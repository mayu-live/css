# MayuCSS

This library wraps [lightningcss](https://github.com/parcel-bundler/lightningcss).

The idea is to use it for CSS parsing/transformations in [Mayu Live](https://github.com/mayu-live/framework).

I do not know Rust. I have no idea what I'm doing.

## Installation

To be disclosed.

## Usage

```ruby
require "mayucss"

result = MayuCSS.transform("/app/components/Hello.css", <<~CSS)
  ul { background: rgb(0 128 255 / 50%); }
  li { border: 1px solid #f0f; }
  .foo { border: 1px solid #f0f; }
  .bar { background: url("./bar.png"); }
CSS

puts "Code:"
puts result.code
puts "Classes:"
pp result.classes
puts "Elements:"
pp result.elements
puts "Dependencies:"
pp result.dependencies
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mayu-live/mayucss.

## License

The gem is available as open source under the terms of the [MPL License](https://opensource.org/licenses/MIT).
