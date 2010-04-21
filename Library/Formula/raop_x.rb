require 'formula'

class RaopX <Formula
  url 'http://www.hersson.net/?download=RaopX_v0.0.4'
  homepage 'http://www.hersson.net/projects/raopx'
  md5 'f251fe50396e1db98dcc26230e656b48'

# depends_on 'cmake'

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-debug", "--disable-dependency-tracking"
#   system "cmake . #{std_cmake_parameters}"
    system "make"
    system "make install"
  end
end
