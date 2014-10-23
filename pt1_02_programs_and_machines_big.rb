# -*- coding: utf-8 -*-
# Part 1
# Chapter 2
# Programs and Machines, 2/2, big-step semantics

# This is the big step semantics version of the small steps semantics version of
# Simple lang

# Here, we're going to dispense with the machines that are running our programs
# and have each step of the program run itself (via an recursive eval fn)

require 'test/unit'
class SimpleLangBigStep < Test::Unit::TestCase

  # In the book this goes on to extend from the constructs built in the small
  # step impl. I'm creating this to stand alone so the required parts are going
  # to be replicated in here.

  module Inspect
    def inspect
      "«#{self}»"
    end
  end

  class Number < Struct.new(:value)
    include Inspect

    def to_s
      value.to_s
    end
  end

  class Boolean < Struct.new(:value)
    include Inspect

    def to_s
      value.to_s
    end
  end

  class Variable < Struct.new(:name)
    include Inspect

    def to_s
      name.to_s
    end
  end

  class Add < Struct.new(:left, :right)
    include Inspect
    def to_s
      "#{left} + #{right}"
    end
  end

  class Multiply < Struct.new(:left, :right)
    include Inspect
    def to_s
      "#{left} * #{right}"
    end
  end

  class LessThan < Struct.new(:left, :right)
    include Inspect
    def to_s
      "#{left} < #{right}"
    end
  end

  class Assign < Struct.new(:name, :expression)
    include Inspect
    def to_s
      "#{name} = #{expression}"
    end
  end

  class DoNothing
    include Inspect
    def to_s
      'do-nothing'
    end

    def ==(other_statement)
      other_statement.instance_of?(DoNothing)
    end
  end

  class If < Struct.new(:condition, :consequence, :alternative)
    include Inspect
    def to_s
      "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end
  end

  class Sequence < Struct.new(:first, :second)
    include Inspect
    def to_s
      "#{first}; #{second}"
    end
  end

  class While < Struct.new(:condition, :body)
    include Inspect
    def to_s
      "while (#{condition}) { #{body} }"
    end
  end





  ##############################################################################
  ## End of replicated stuff, beginning of new stuff ###########################
  ##############################################################################


  class Number
    def evaluate(environment)
      self
    end
  end

  class Boolean
    def evaluate(environment)
      self
    end
  end

  class Variable
    def evaluate(environment)
      environment[name]
    end
  end

  class Add
    def evaluate(environment)
      Number.new(left.evaluate(environment).value + right.evaluate(environment).value)
    end
  end

  class Multiply
    def evaluate(environment)
      Number.new(left.evaluate(environment).value * right.evaluate(environment).value)
    end
  end

  class LessThan
    def evaluate(environment)
      Boolean.new(left.evaluate(environment).value < right.evaluate(environment).value)
    end
  end


  def test_eval
    assert_equal(Number.new(23), Number.new(23).evaluate({}))
    assert_equal(Number.new(23), Variable.new(:x).evaluate({x: Number.new(23)}))

    exp = LessThan.new(Add.new(Variable.new(:x),
                               Number.new(2)),
                       Variable.new(:y))
    assert_equal(Boolean.new(true), exp.evaluate({ x: Number.new(2), y: Number.new(5) }))

  end

  class Assign
    def evaluate(environment)
      environment.merge({ name => expression.evaluate(environment) })
    end
  end

  class DoNothign
    def evaluate(environment)
      environment
    end
  end

  class If
    def evaluate(environment)
      case condition.evaluate(environment)
      when Boolean.new(true)
        consequence.evaluate(environment)
      when Boolean.new(false)
        alternative.evaluate(environment)
      end
    end
  end

  class Sequence
    def evaluate(environment)
      second.evaluate(first.evaluate(environment))
    end
  end

  def test_statement
    statement = Sequence.new(Assign.new(:x, Add.new(Number.new(1),
                                                    Number.new(1))),
                             Assign.new(:y, Add.new(Variable.new(:x),
                                                    Number.new(3))))
    new_env = statement.evaluate({})
    assert_equal({x: Number.new(2), y: Number.new(5)}, new_env)
  end

  class While
    def evaluate(environment)
      # Recursive eval, when the condition is true we eval the body to produce a
      # new environment and thread that environment back through into our own
      # evaluate function (i.e. this one we are in right now)
      case condition.evaluate(environment)
      when Boolean.new(true)
        evaluate(body.evaluate(environment))
      when Boolean.new(false)
        environment
      end
    end
  end

  def test_while_loop
    expr = While.new(LessThan.new(Variable.new(:x), Number.new(5)),
                     Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3))))
    env = { x: Number.new(1) }

    new_env = expr.evaluate(env)
    assert_equal({x: Number.new(9)}, new_env)
  end

  ##############################################################################
  ## Now we're going to try something interesting, generating ruby code from  ##
  ## our AST code.                                                            ##
  ##############################################################################
  ## Our generated code will be a String in the form of a Ruby proc. We can   ##
  ## then `eval` the String and `.call` the proc to get the result            ##
  ##############################################################################

  class Number
    def to_ruby
      "-> e { #{value.inspect} }"
    end
  end

  class Boolean
    def to_ruby
      "-> e { #{value.inspect} }"
    end
  end

  def test_ruby_values
    assert_equal(5, eval(Number.new(5).to_ruby).call({}))
    assert_equal(true, eval(Boolean.new(true).to_ruby).call({}))
    assert_equal(false, eval(Boolean.new(false).to_ruby).call({}))
  end

  class Variable
    def to_ruby
      "-> e { e[#{name.inspect}] }"
    end
  end

  def test_ruby_variable
    assert_equal(7, eval(Variable.new(:x).to_ruby).call({x: 7}))
  end

  class Add
    def to_ruby
      "-> e { (#{left.to_ruby}).call(e) + (#{right.to_ruby}).call(e) }"
    end
  end

  class Multiply
    def to_ruby
      "-> e { (#{left.to_ruby}).call(e) * (#{right.to_ruby}).call(e) }"
    end
  end

  class LessThan
    def to_ruby
      "-> e { (#{left.to_ruby}).call(e) < (#{right.to_ruby}).call(e) }"
    end
  end

  def test_ruby_addition
    environment = { x: 3 }
    proc = eval(Add.new(Variable.new(:x),
                        Number.new(1)).to_ruby)
    assert_equal(4, proc.call(environment))

    proc2 = eval(LessThan.new(Add.new(Variable.new(:x),
                                      Number.new(1)),
                              Number.new(3)).to_ruby)
    assert_equal(false, proc2.call(environment))
  end

  # Statements

  class Assign
    def to_ruby
      "-> e { e.merge({ #{name.inspect} => (#{expression.to_ruby}).call(e) }) }"
    end
  end

  def test_ruby_assign
    statement = Assign.new(:y, Add.new(Variable.new(:x), Number.new(1)))
    new_env = eval(statement.to_ruby).call({x: 3})
    assert_equal({x: 3, y: 4}, new_env)
  end

  class DoNothing
    def to_ruby
      '-> e { e }'
    end
  end


  class If
    def to_ruby
      "-> e { if (#{condition.to_ruby}).call(e)" +
        " then (#{consequence.to_ruby}).call(e)" +
        " else (#{alternative.to_ruby}).call(e)" +
        " end }"
    end
  end

  class Sequence
    def to_ruby
      "-> e { (#{second.to_ruby}).call((#{first.to_ruby}).call(e)) }"
    end
  end

  class While
    def to_ruby
      "-> e {" +
        " while (#{condition.to_ruby}).call(e); e = (#{body.to_ruby}).call(e) end;" +
        " e" +
        " }"
    end
  end

  def test_ruby_while
    statement = While.new(LessThan.new(Variable.new(:x),
                                       Number.new(5)),
                          Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3))))
    proc = eval(statement.to_ruby)
    new_env = proc.call({ x: 1})
    assert_equal({x: 9}, new_env)
  end














end
