require "bundler/setup"
require "mayucss"

result = MayuCSS.transform("/app/components/Hello.css", <<~CSS)
  ul { background: rgb(0 128 255 / 50%); }
  li { border: 1px solid #f0f; }
  .foo { border: 1px solid #f0f; }
  .bar { background: url("./bar.png"); }
CSS

def title(str) = puts("\e[1;3m ** #{str} ** \e[0m")

title "code"
puts result.code
puts

title "classes"
pp result.classes
puts

title "elements"
pp result.elements
puts

title "dependencies"
pp result.dependencies
