# -*- coding: utf-8 -*-
# The book begins by informing us that Ruby will be used to demonstrate the
# concepts explained in the book and that it was chosen because of its "clarity
# and flexibility".
# All of the book code should work with Ruby 1.9 and 2.0, but I'm going to use
# 2.1 and make modifications when it's interesting to do so, as such, I won't
# hold to that promise when to do so would constrain or prevent me from reaching
# the goal I want.

# This chapter goes on to show irb, starting it will `irb --simple-prompt`
# To record what I did I'm going to record it here as asserts, view the left
# operand as the expected value (i.e. output) and the right expression as what
# the book types into the repl

# I'll also be running irb inside Emacs with `inf-ruby`,
# https://github.com/nonsequitur/inf-ruby

require 'test/unit'
class JustEnoughRuby < Test::Unit::TestCase

## Interactive Ruby Shell
  def test_interactive_ruby_shell
    assert_equal(3, 1 + 2)
    assert_equal(11, 'hello world'.length)
    x = 2
    y = 3
    z = x + y
    assert_equal(30, x * y * z)
  end

  ## Values
  def test_values_basic_data
    assert_equal(true, (true && false) || true)
    assert_equal(42, (3 + 3) * (14 / 2))
    assert_equal('hello world', 'hello' + ' world')
    # TODO: Is slice a list based op or only strings?
    assert_equal('w', 'hello world'.slice(6))

    # Symbols are lightweight, immutable values representing a name
    # So far they seem the same as Clojure symbols and have a similar usage in
    # hashes (maps) to represent a key name
    assert_equal(:my_symbol, :my_symbol)
    assert_not_equal(:my_symbol, :another_symbol)

    # nil indicates no value.
    # Here there is no 11th character
    assert_equal(nil, 'hello world'.slice(11))
  end

  def test_values_data_structures_arrays
    numbers = ['zero', 'one', 'two']
    assert_equal(['zero', 'one', 'two'], numbers)
    assert_equal('one', numbers[1])
    # values can be destructively pushed on to the end
    numbers.push('three', 'four')
    assert_equal(['zero', 'one', 'two', 'three', 'four'], numbers)
    # and non-destructively droped to produce a new array
    # TODO: is there a non-destructive push equivalent?
    assert_equal(['two', 'three', 'four'], numbers.drop(2))
    assert_equal(['zero', 'one', 'two', 'three', 'four'], numbers)
  end

  def test_values_data_structures_ranges
    ages = 18..30
    # ranges are inclusive of min and max
    assert_equal([18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30], ages.entries)
    assert_equal(true, ages.include?(25))
    assert_equal(false, ages.include?(33))
    # Infinite ranges are also a thing
    assert_equal(true, (0..Float::INFINITY).include?(Float::INFINITY))
  end

  def test_values_data_structures_hashes
    # Hashes in Ruby provide a key to value mapping. They're usually called maps
    # or dictionaries in other languages, and usually use a hashing function on
    # the key to provide effeciant performance on lookups, inserts, etc.
    # Instead of checking, I think we can assume that Ruby hashes take that name
    # because they use a hashing function.
    fruit = { 'a' => 'apple', 'b' => 'banana', 'c' => 'coconut' }
    # Access is the same mechanism as arrays
    assert_equal('banana', fruit['b'])
    # In fact, integer access is available too, exactly the same as accessing
    # array indexes
    assert_equal('banana', {5 => 'banana'}[5])
    # new elements can be destructively added
    fruit['d'] = 'date'
    assert_equal('date', fruit['d'])

    # Hashes often use symbols as keys and there is some syntactic sugar to
    # represent this
    dimensions_normal = { :width => 1000, :height => 2250, :depth => 250 }
    dimensions_sugar = { width: 1000, height: 2250, depth: 250 }
    assert_equal(dimensions_normal, dimensions_sugar)

    # Also
    assert_equal(1000, dimensions_normal[:width])

    # Aside: I loathe syntactic sugar, this especially. Why not replace the
    # structure with { key val, key val, ... } if you want sugar instead of
    # having a symbol specific impl and a longer normal impl. Oh well.
  end


  def test_values_data_structures_procs
    # procs are lambdas
    multiply = -> x, y { x * y }
    assert_equal(54, multiply.call(6, 9))

    # or..
    assert_equal(54, multiply[6, 9])
    # but seriously, why not just multiply(6,9) ? ¯\_(ツ)_/¯
  end

  def test_control_flow
    # Control flow seems to be in the form of expressions rather than statements

    assert_equal('less', if 2 < 3
                           'less'
                           else
                           'more'
                           end)

    pluralize = -> number {
      case number
      when 1
        'one'
      when 2
        'a couple'
      else
        'many'
      end}
    assert_equal('a couple', pluralize.call(2))
    assert_equal('many', pluralize.call(10))

    # Cases are expressions
    assert_equal('one', case 1
                        when 1
                          'one'
                        else
                          'many'
                        end)

    # While loops are statements, not expressions
    x = 1
    while x < 1000
      x = x * 2
    end
    assert_equal(1024, x)

    # not expression proof. The result of a while loop is nil
    x = 1
    assert_equal(nil, while x == 1
      x = x - 1
    end)

  end

  def test_objects_and_methods
    o = Object.new
    def o.add(x,y)
      x + y
    end
    assert_equal(5, o.add(2,3))

    def o.add_twice(x,y)
      # Inside an object context we can refer ourself as `self`, self is assumed
      # by default, allowing us to use functions without prefixing with `self.`
      self.add(x,y) + add(x,y)
    end
    assert_equal(10, o.add_twice(2,3))

    # We can create top-level methods on a special object called `main`
    # Are these the same as global methods? Can we namespace them?
    def multiply(a,b)
      a * b
    end
    assert_equal(6, multiply(2,3))

  end

  class Calculator
    def divide(x,y)
      x / y
    end
  end

  def test_classes_and_modules
    c = Calculator.new
    assert_equal(Calculator, c.class)
    assert_equal(5, c.divide(10,2))
  end

  class MultiplyingCalculator < Calculator
    # Classes can be inherited from
    # This includes Calculator's divide fn
    def multiply(x,y)
      x * y
    end
  end

  def test_classes_and_modules_inheritance
    mc = MultiplyingCalculator.new
    assert_equal(MultiplyingCalculator, mc.class)
    assert_equal(Calculator, mc.class.superclass)
    assert_equal(20, mc.multiply(10,2))
    assert_equal(5, mc.divide(10,2))
  end

  class BinaryCalculator < MultiplyingCalculator
    # Override a method just by redefining it
    def multiply(x,y)
      super(x,y).to_s(2)
    end
  end

  def test_classes_and_modules_super
    bc = BinaryCalculator.new
    assert_equal('10100', bc.multiply(10,2))
  end

  module Addition
    def add(x,y)
      x + y
    end
  end

  class AdditionCalculator
    include Addition
  end

  def test_classes_and_modules_module
    ac = AdditionCalculator.new
    assert_equal(12, ac.add(10,2))
  end

  def test_misc_features
    # local variables
    greeting = 'hello'
    assert_equal('hello', greeting)

    # exploding array assignment
    width, height, depth = [1000, 2250, 250]
    assert_equal(1000, width)
    assert_equal(2250, height)
    assert_equal(250, depth)

    # String Interpolation in double quoted strings
    assert_equal('hello world', "hello #{'dlrow'.reverse}")

    # We can control how an object is represented as a String with the to_s fn
    o = Object.new
    def o.to_s
      'a new object'
    end
    # String interpolation will automatically call to_s on non-strings
    assert_equal('hello a new object', "hello #{o}")
    assert_equal('hello a new object', "hello #{o.to_s}")

    # Objects have an inspect fn that IRB will call to display them
    # TODO: Does this have any other non-IRB use? Logging?
    def o.inspect
      '[my object]'
    end
    assert_equal('hello [my object]', "hello #{o.inspect}")

    # Puts prints. I guess we can assert test any of this
    x = 128
    while x < 1000
      puts "x is #{x}"
      x = x * 2
    end

    # variadic methods, there can only be one variadic parameter
    def join_with_commas(*words)
      words.join(', ')
    end
    assert_equal('one, two, three', join_with_commas('one', 'two', 'three'))

    # but there can be normal parameters on either side
    def join_with_commas(before, *words, after)
      before + words.join(', ') + after
    end
    assert_equal('Testing: one, two, three.', join_with_commas('Testing: ', 'one', 'two', 'three', '.'))

    # arrays can be exploded into function args
    args = ['Testing: ', 'one', 'two', 'three', '.']
    assert_equal('Testing: one, two, three.', join_with_commas(*args))

    # and in var assignment
    before, *words, after = args
    assert_equal('Testing: ', before)
    assert_equal(['one', 'two', 'three'], words)
    assert_equal('.', after)

  end

  def test_blocks
    # What are blocks? Weird lambda things?

    def do_three_times
      yield
      yield
      yield
    end
    x = 0
    do_three_times { x = x + 1 }
    assert_equal(3, x)

    # A block can also be specified with do and end instead of curly braces
    do_three_times do x = x + 1 end
    assert_equal(6, x)

    # A block can also take arguments
    def do_three_times
      yield('first')
      yield('second')
      yield('third')
    end

    str = ''
    do_three_times { |w| str = str + w }
    assert_equal('firstsecondthird', str)

    # yield returns the result of the block
    def collect_three_things
      [yield('first'), yield('second'), yield('third')].join(', ')
    end
    assert_equal('TSRIF, DNOCES, DRIHT', collect_three_things { |w| w.upcase.reverse })

  end

  def test_enumerable
    # Enumerable is a mobile included by Array, Hash, Range and other classes
    # and provides functions for traversing, searching and sorting, mostly by
    # accepting a block as predicate

    # Count is like SQLs count
    assert_equal(5, (1..10).count { |number| number.even? })

    # Select is a filter
    assert_equal([2, 4, 6, 8, 10], (1..10).select { |n| n.even? })

    # Any? checks if any element matches the predicate
    assert_equal(true, (1..10).any? { |n| n < 8 })

    # All? checks if all element matches the predicate
    assert_equal(false, (1..10).all? { |n| n < 8 })

    # Each does side effects
    x = 0
    (1..5).each { |n| x = x + n }
    assert_equal(15, x)

    # Map maps
    assert_equal([3,6,9,12,15], [1,2,3,4,5].map { |n| n * 3 })

    # In the case of many examples above where we're calling arg.fn we can use
    # a shortcut &:message to do the same
    assert_equal(5, (1..10).count(&:even?))
    assert_equal(['ONE', 'TWO', 'THREE'], ['one', 'two', 'three'].map(&:upcase))

    # Flatmap flatmaps
    assert_equal([['o', 'n', 'e'],
                  ['t', 'w', 'o'],
                  ['t', 'h', 'r', 'e', 'e']], ['one', 'two', 'three'].map(&:chars))

    assert_equal(['o', 'n', 'e', 't', 'w', 'o', 't', 'h', 'r', 'e', 'e'],
                 ['one', 'two', 'three'].flat_map(&:chars))

    # And inject is a reduce
    assert_equal(15, [1, 2, 3, 4, 5].inject(0) { |acc, n| acc + n })
  end

  class Point < Struct.new(:x, :y)
  end

  def test_struct
    # Struct is a class to generate Ruby classes, presumably only for data
    # storage. It provides getters and setters and an equality method
    p = Point.new(2, 3)
    assert_equal(2, p.x)
    assert_equal(3, p.y)

    assert_equal(Point.new(2,3), Point.new(2,3))
  end

  class Point
    # Extra methods can be defined on a Struct
    # This class definition is "monkey patching" the class defined above, it
    # adds the + method but retains everything else
    def +(other_point)
      Point.new(x + other_point.x, y + other_point.y)
    end
  end

  def test_struct_methods
    p = Point.new(2, 3)
    p2 = Point.new(10, 20)
    p3 = p + p2
    assert_equal(12, p3.x)
    assert_equal(23, p3.y)
  end

  class Point
    # A class can be monkey patches as many times as you like
    def -(other_point)
      Point.new(x - other_point.x, y - other_point.y)
    end
  end

  def test_struct_monkey_patched_minus
    p1 = Point.new(10, 20)
    p2 = Point.new(2, 3)
    p3 = p1 - p2
    assert_equal(8, p3.x)
    assert_equal(17, p3.y)
  end

  class String
    # Any classes can be monkey patch, including Ruby internals
    def shout
      upcase + "!!!!"
    end
  end

  def test_monkey_patched_string
    # TODO: this errors. Why?
    # NoMethodError: undefined method `shout' for "hello":String
    # assert_equal('HELLO!!!!', 'hello'.shout)
  end

  I_AM_A_CONSTANT = 10
  # Constants can be redefined. It won't cause an error but warnings will be
  # output
  I_AM_A_CONSTANT_THAT_WILL_BE_REDEFINED_LOL = 10
  I_AM_A_CONSTANT_THAT_WILL_BE_REDEFINED_LOL = 11

end
