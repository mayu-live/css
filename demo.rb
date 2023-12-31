require "bundler/setup"
require "mayu/css"
require "json"
require "io/console"
require "digest/sha2"
require "base64"

def separator = puts "\e[0m#{"▂" * $stdout.winsize.last}\e[0m"
def header(text) = puts "\e[1;35m#{text}\e[0m"
def code(text) = puts "\e[33m#{text.chomp}\e[0m"

header "minify"

code Mayu::CSS.minify(__FILE__, <<~CSS)
  foo {
    background: rgb(50 32 42 / 50%);
    background-image: url("foobar.png");
  }
  .bar {
    background: rgb(50 32 42 / 50%);
  }
CSS

separator

header "serialize"

pp Mayu::CSS.serialize(__FILE__, <<~CSS)
  foo {
    background: rgb(50 32 42 / 50%);
  }
  .bar {
    background: rgb(50 32 42 / 50%);
  }
CSS

separator

result = Mayu::CSS.transform(__FILE__, <<~CSS, minify: false)
  foo {
    background: rgb(50 32 42 / 50%);
    background-image: url("foobar.png");
  }
  .b-ar {
    background: rgb(50 32 42 / 50%);
  }
  .hopp {
    composes: b-ar;
  }
CSS

pp result

header "Classes"
pp result.classes
header "Elements"
pp result.elements
header "Code"
code result.code
header "Dependencies"
pp result.dependencies
header "Exports"
pp result.exports

separator

header "dependencies"

res = Mayu::CSS.transform(__FILE__, <<~CSS, minify: false)
  @import url("landscape.css") screen and (orientation: landscape);
  @import url("gridy.css") supports(display: grid) screen and (max-width: 400px);

  .foo {
    composes: hello from "./asd.css";
    background: url("hello.png");
  }
CSS

pp res.dependencies
pp res.exports

puts(
  res.replace_dependencies do |dependency|
    filename = [
      Base64.urlsafe_encode64(Digest::SHA256.digest(dependency.url), padding: false),
      File.extname(dependency.url)
    ].join
    "/.mayu/static/#{filename}"
  end
)

separator

header "errors"

begin
  Mayu::CSS.transform(__FILE__, <<~CSS).code
    foo {
      background: rgb(50 32 42 / 50%);
    }
    .bar {
      background: rgb(50 32 42 / 50%
      color: #f0f
    }
  CSS
rescue => e
  puts "\e[31m#{e.inspect}\e[0m"
end
