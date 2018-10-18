# exchange

A gem to easily perform currency conversions directly on numbers in Ruby.

## Installation

Add it to your Gemfile:

```ruby
gem "exchange", "~> 1.2"
```

Or install it manually, and require it:

```bash
gem install exchange
```

```ruby
require "exchange"
```

## Usage

```ruby
1.in(:eur).to(:usd)
1.in(:eur).to(:usd, at: 5.days.ago)
```


