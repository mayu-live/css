require "bundler/setup"
require "mayu/css"
require "json"
require "io/console"

def separator = puts "\e[3m#{" " * $stdout.winsize.last}\e[0m"
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

pp JSON.parse(Mayu::CSS.serialize(__FILE__, <<~CSS))
  foo {
    background: rgb(50 32 42 / 50%);
  }
  .bar {
    background: rgb(50 32 42 / 50%);
  }
CSS

separator

result =  Mayu::CSS.transform(__FILE__, <<~CSS)
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
