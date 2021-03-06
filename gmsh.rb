class GmshSvnStrategy < SubversionDownloadStrategy
  def quiet_safe_system(*args)
    super *args + ["--username", "gmsh", "--password", "gmsh"]
  end
end

class Gmsh < Formula
  desc "Gmsh is a 3D grid generator with a build-in CAD engine."
  homepage "http://geuz.org/gmsh"
  url "http://geuz.org/gmsh/src/gmsh-2.10.1-source.tgz"
  sha256 "a47f15541db038c9cb00f004d13c5648a46c3d8ebd6e0bf3b56f9274e13f505d"

  head "https://geuz.org/svn/gmsh/trunk", :using => GmshSvnStrategy

  bottle do
    cellar :any
    sha256 "65d05d677a3ab929ad126f6c93c9ddfb70b8be32995ce68c6920178f8359ca76" => :el_capitan
    sha256 "b039831f02f123a2cb39de1055e345dc8465483396f0d10284a9d5aa4796a46b" => :yosemite
    sha256 "8faf0079b79a7b1690154aa6df8ba8c25bf007a7ddb26bbb09b34a069814c2ee" => :mavericks
  end

  depends_on :fortran
  depends_on :mpi => [:cc, :cxx, :f90, :recommended]
  depends_on "cmake" => :build
  depends_on "petsc" => :optional
  depends_on "slepc" => :optional
  depends_on "fltk" => :optional
  depends_on "cairo" if build.with? "fltk"

  option "with-oce",               "Build with oce support (conflicts with opencascade)"
  option "without-opencascade",    "Build without opencascade support"

  if build.with?("opencascade") && build.with?("oce")
    odie "gmsh: --without-opencascade must be specified when using --with-oce"
  else
    depends_on "opencascade"      if build.with? "opencascade"
    depends_on "oce"              if build.with? "oce"
  end

  def install
    # In OS X, gmsh sets default directory locations as if building a
    # binary. These locations must be reset so that they make sense
    # for a Homebrew-based build.
    args = std_cmake_args + ["-DENABLE_OS_SPECIFIC_INSTALL=0",
                             "-DGMSH_BIN=#{bin}",
                             "-DGMSH_LIB=#{lib}",
                             "-DGMSH_DOC=#{share}/gmsh",
                             "-DGMSH_MAN=#{man}"]

    if build.with? "oce"
      ENV["CASROOT"] = Formula["oce"].opt_prefix
      args << "-DENABLE_OCC=ON"
    elsif build.with? "opencascade"
      ENV["CASROOT"] = Formula["opencascade"].opt_prefix
      args << "-DENABLE_OCC=ON"
    else
      args << "-DENABLE_OCC=OFF"
    end

    if build.with? "petsc"
      ENV["PETSC_DIR"] = Formula["petsc"].opt_prefix
      ENV["PETSC_ARCH"] = "real"
    else
      args << "-DENABLE_PETSC=OFF"
    end

    if build.with? "slepc"
      ENV["SLEPC_DIR"] = "#{Formula["slepc"].opt_prefix}/real"
    else
      args << "-DENABLE_SLEPC=OFF"
    end

    if (build.with? "petsc") || (build.with? "slepc")
      args << "-DENABLE_MPI=ON" if build.with? "mpi"
    end

    # Make sure native file dialogs are used
    args << "-DENABLE_NATIVE_FILE_CHOOSER=ON"

    # Build a shared library such that others can link
    args << "-DENABLE_BUILD_LIB=ON"
    args << "-DENABLE_BUILD_SHARED=ON"

    # Build with or without GUI
    args << "-DENABLE_FLTK=OFF" if build.without? "fltk"

    mkdir "build" do
      system "cmake", "..", *args
      system "make"
      system "make", "install"

      # move onelab.py into libexec instead of bin
      rm "#{bin}/onelab.py"
      libexec.install "onelab.py"
    end
  end

  def caveats
    "To use onelab.py set your PYTHONDIR to #{libexec}"
  end

  test do
    system "#{bin}/gmsh", "#{share}/doc/gmsh/tutorial/t1.geo", "-parse_and_exit"
  end
end
