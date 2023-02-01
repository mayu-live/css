require "bundler/setup"
require "mayucss"
require "json"

puts MayuCSS.minify(__FILE__, <<~CSS)
foo {
  background: rgb(50 32 42 / 50%);
  background-image: url("foobar.png");
}
.bar {
  background: rgb(50 32 42 / 50%);
}
CSS

puts "############"

pp JSON.parse(MayuCSS.serialize(__FILE__, <<~CSS))
foo {
  background: rgb(50 32 42 / 50%);
}
.bar {
  background: rgb(50 32 42 / 50%);
}
CSS

puts "############"

result =  MayuCSS.transform(__FILE__, <<~CSS)
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
