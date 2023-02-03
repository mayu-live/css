require "bundler/setup"
require "mayu/css"
require "json"

puts Mayu::CSS.minify(__FILE__, <<~CSS)
foo {
  background: rgb(50 32 42 / 50%);
  background-image: url("foobar.png");
}
.bar {
  background: rgb(50 32 42 / 50%);
}
CSS

puts "############"

pp JSON.parse(Mayu::CSS.serialize(__FILE__, <<~CSS))
foo {
  background: rgb(50 32 42 / 50%);
}
.bar {
  background: rgb(50 32 42 / 50%);
}
CSS

puts "############"

result =  Mayu::CSS.transform(__FILE__, <<~CSS)
foo {
  background: rgb(50 32 42 / 50%);
  background-image: url("foobar.png");
}
.b-ar {
  background: rgb(50 32 42 / 50%);
}
CSS

p result.classes
p result.elements
p result.code
p result.dependencies
