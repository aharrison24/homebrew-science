class Fstar < Formula
  desc "Language with a type system for program verification"
  homepage "http://fstar.gforge.inria.fr/"
  url "https://github.com/FStarLang/FStar.git",
    :tag => "v0.9.0",
    :revision => "f24457213f4007302873f6d42eb2cf8094fa45d0"
  head "https://github.com/FStarLang/FStar.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "df55be25b1af6304340f7bc87a0d8c4409f62639bed5d4ec3b0f6e36d20020f2" => :el_capitan
    sha256 "667b64d0a14dfd6f0e1d663b380829d52aa16c6e57f1d1fa360beff990e1c17d" => :yosemite
    sha256 "3f1ee333bd0477e225c80925666043a684db65c2af486c78edc891d312a2eebc" => :mavericks
  end

  depends_on "mono"   => :build
  depends_on "fsharp" => :build
  depends_on "opam"   => :build
  depends_on "ocaml"  => :recommended
  depends_on "homebrew/science/z3"

  resource "ocamlfind" do
    url "http://download.camlcity.org/download/findlib-1.5.5.tar.gz"
    sha256 "aafaba4f7453c38347ff5269c6fd4f4c243ae2bceeeb5e10b9dab89329905946"
  end

  resource "batteries" do
    url "https://github.com/ocaml-batteries-team/batteries-included/archive/v2.3.1.tar.gz"
    sha256 "df778b90fcdb26288d9d92a86e51dd75d6bb7c6e41888c748c7508e8ea58b1d4"
  end

  def install
    ENV.deparallelize

    opamroot = buildpath/"opamroot"
    ENV["OPAMROOT"] = opamroot
    ENV["OPAMYES"] = "1"
    system "opam", "init", "--no-setup"
    archives = opamroot/"repo/default/archives"
    modules = []
    resources.each do |r|
      r.verify_download_integrity(r.fetch)
      original_name = File.basename(r.url)
      cp r.cached_download, archives/original_name
      modules << "#{r.name}=#{r.version}"
    end
    system "opam", "install", *modules

    system "make", "-C", "src/"
    system "opam", "config", "exec", "--",
    "make", "-C", "src/ocaml-output/"

    bin.install "src/ocaml-output/fstar.exe"
    prefix.install "README.md"

    (libexec/"stdlib").install Dir["lib/*"]
    (libexec/"contrib").install Dir["contrib/*"]
    (libexec/"examples").install Dir["examples/*"]
    (libexec/"tutorial").install Dir["doc/tutorial/*"]
    (libexec/"src").install Dir["src/*"]
    (libexec/"licenses").install "LICENSE-fsharp.txt", Dir["3rdparty/licenses/*"]

    prefix.install_symlink libexec/"stdlib"
    prefix.install_symlink libexec/"contrib"
    prefix.install_symlink libexec/"examples"
    prefix.install_symlink libexec/"tutorial"
    prefix.install_symlink libexec/"src"
    prefix.install_symlink libexec/"licenses"
  end

  def caveats; <<-EOS.undent
    F* standard library is available in #{prefix}/stdlib:
    - alias fstar='fstar.exe --include #{prefix}/stdlib --prims prims.fst'

    F* code can be extracted to OCaml code.
    To compile the generated OCaml code, you must install the
    package 'batteries' from the Opam package manager:
    - brew install opam
    - opam install batteries

    F* code can be extracted to F# code.
    To compile the generated F# (.NET) code, you must install
    Mono and the FSharp compilers:
    - brew install mono
    - brew install fsharp
    EOS
  end

  test do
    system "#{bin}/fstar.exe",
    "--include", "#{prefix}/stdlib",
    "--include", "#{prefix}/examples/unit-tests",
    "--prims", "prims.fst",
    "--admit_fsi", "FStar.Set",
    "set.fsi", "heap.fst",
    "st.fst", "all.fst",
    "list.fst", "string.fst",
    "int32.fst", "unit1.fst",
    "unit2.fst", "testset.fst"
  end
end
