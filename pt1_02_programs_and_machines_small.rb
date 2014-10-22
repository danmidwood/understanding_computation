# -*- coding: utf-8 -*-
# Part 1
# Chapter 2
# Programs and Machines, 1/2, small-step semantics

# "Computation is a name for what a computer does"
# The page goes on to explain that for computation we need three basic
# ingredients, a machine, a programming language, and something written in that
# language, i.e. a program. Part one is going to be about these three things.

# Chapter 2, The Meaning of Programs
# In which we design and implement a toy programming language.

# "To completely specify a programming language, we need to provide two things:
# * a syntax, which describes what programs look like
# * a semantics, which describes what programs mean

# Syntax rules allow us to distinguish potentially valud programs from the
# nonsensical ones. They also provide information on how to read ambiguous
# programs (operator precedencce given as one example)

# We're going to explore the semantics of a toy PL that we'll call Simple. The
#  book then shows Simple's inference rules that defines a "reduction relation"
# on Simple's AST

# Again, let's wrap everything up in a test class provide asserts

require 'test/unit'
class SimpleLang < Test::Unit::TestCase


  # Expressions
  class Number < Struct.new(:value)
  end

  class Add < Struct.new(:left, :right)
  end

  class Multiply < Struct.new(:left, :right)
  end

  # Building an AST from these expressions
  puts "AST for (+ (* 1 2) (* 3 4))"
  puts Add.new(Multiply.new(Number.new(1), Number.new(2)),
               Multiply.new(Number.new(3), Number.new(4)))

  # To make the AST easier to read we can override `to_s` and `inspect` on each
  # expression
  class Number
    def to_s
      value.to_s
    end

    def inspect
      "«#{self}»"
    end
  end

  class Add
    def to_s
      "#{left} + #{right}"
    end

    def inspect
      "«#{self}»"
    end
  end

  class Multiply
    def to_s
      "#{left} * #{right}"
    end

    def inspect
      "«#{self}»"
    end
  end

  puts "Same AST, with custom to_s and inspect"
  puts Add.new(Multiply.new(Number.new(1), Number.new(2)),
               Multiply.new(Number.new(3), Number.new(4)))


  # Expressions that are not values are reducible towards values, let's add that
  class Number
    def reducible?
      false
    end
  end

  class Add
    def reducible?
      true
    end
  end

  class Multiply
    def reducible?
      true
    end
  end

  # Now we can test if an expression is reducible
  def test_is_reducible?
    assert_equal(false, Number.new(1).reducible?)
    assert_equal(true, Add.new(Number.new(1), Number.new(2)).reducible?)
  end

  # Since Add and Multiply can be reduced, let's add a `reduce` fn to them
  class Add
    def reduce
      if left.reducible?
        Add.new(left.reduce, right)
      elsif right.reducible?
        Add.new(left, right.reduce)
      else
        Number.new(left.value + right.value)
      end
    end
  end

  class Multiply
    def reduce
      if left.reducible?
        Add.new(left.reduce, right)
      elsif right.reducible?
        Add.new(left, right.reduce)
      else
        Number.new(left.value * right.value)
      end
    end
  end


  def test_reducing
    expr_0 = Add.new(Multiply.new(Number.new(1), Number.new(2)),
                   Multiply.new(Number.new(3), Number.new(4)))
    assert_equal('1 * 2 + 3 * 4', expr_0.to_s)
    expr_1 = expr_0.reduce
    assert_equal('2 + 3 * 4', expr_1.to_s)
    expr_2 = expr_1.reduce
    assert_equal('2 + 12', expr_2.to_s)
    expr_3 = expr_2.reduce
    assert_equal('14', expr_3.to_s)
    assert_equal(false, expr_3.reducible?)
  end


  # So, that's great but it's a lot of work for us. Let's build a machine to do
  # it instead

  class Machine < Struct.new(:expression)
    def step
      self.expression = expression.reduce
    end

    def run
      while expression.reducible?
        step
      end
      expression
    end
  end

  def test_machine
    expr = Add.new(Multiply.new(Number.new(1), Number.new(2)),
                     Multiply.new(Number.new(3), Number.new(4)))
    machine = Machine.new(expr)
    result = machine.run
    assert_equal(false, result.reducible?)
    assert_equal(Number, result.class)
    assert_equal(14, result.value)
  end


  # To show how simple it is to extend our machine we will add booleans and a
  # less than operator

  class Boolean < Struct.new(:value)
    def to_s
      value.to_s
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      false
    end
  end

  class LessThan < Struct.new(:left, :right)
    def to_s
      "#{left} < #{right}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

    def reduce
      if left.reducible?
        LessThan.new(left.reduce, right)
      elsif right.reducible?
        LessThan.new(left, right.reduce)
      else
        Boolean.new(left.value < right.value)
      end
    end
  end

  def test_less_than
    expr = LessThan.new(Number.new(5),
                        Add.new(Number.new(2), Number.new(2)))
    machine = Machine.new(expr)
    result = machine.run
    assert_equal(false, result.value)
  end

end


################################################################################
### At this point we hit snags from running the script instead of typing this ##
### into IRB. So let's start a new test class and redefine the things we need.##
################################################################################
class SimpleLang2  < Test::Unit::TestCase


  ##############################################################################
  ## Redefinitions.  ###########################################################
  ##############################################################################
  ## Everything from above minus the reduce fns and the machine, these will   ##
  ## later be redefinied                                                      ##
  ##############################################################################

  class Number < Struct.new(:value)
    def to_s
      value.to_s
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      false
    end

  end

  class Add < Struct.new(:left, :right)
    def to_s
      "#{left} + #{right}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

  end

  class Multiply < Struct.new(:left, :right)
    def to_s
      "#{left} * #{right}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

  end

  class Boolean < Struct.new(:value)
    def to_s
      value.to_s
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      false
    end
  end

  class LessThan < Struct.new(:left, :right)
    def to_s
      "#{left} < #{right}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end
  end

  ##############################################################################
  ## End of Redefinitions, beginning of the new ################################
  ##############################################################################


  # Variables
  class Variable < Struct.new(:name)
    def to_s
      name.to_s
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end
  end


  # A variable needs to be stored somewhere, we're going to do that in an
  # "environment" that will be a hash of var name to value, and managed by the
  # machine
  class Variable
    def reduce(environment)
      environment[name]
    end
  end

  # Now we redefine our reduce fn on our expression to be environment-aware
  class Add
    def reduce(environment)
      if left.reducible?
        Add.new(left.reduce(environment), right)
      elsif right.reducible?
        Add.new(left, right.reduce(environment))
      else
        Number.new(left.value + right.value)
      end
    end
  end

  class Multiply
    def reduce(environment)
      if left.reducible?
        Multiply.new(left.reduce(environment), right)
      elsif right.reducible?
        Multiply.new(left, right.reduce(environment))
      else
        Number.new(left.value * right.value)
      end
    end
  end

  class LessThan
    def reduce(environment)
      if left.reducible?
        LessThan.new(left.reduce(environment), right)
      elsif right.reducible?
        LessThan.new(left, right.reduce(environment))
      else
        Boolean.new(left.value < right.value)
      end
    end
  end

  # And now, let's redefine our machine to manage the state and pass it through
  # on the reductions
  class Machine < Struct.new(:expression, :environment)
    def step
      self.expression = expression.reduce(environment)
    end

    def run
      while expression.reducible?
        step
      end
      expression
    end
  end

  def test_environment_in_machine
    expr = Add.new(Variable.new(:x), Variable.new(:y))
    env = {x: Number.new(3), y: Number.new(4)}
    machine = Machine.new(expr, env)
    assert_equal(7, machine.run.value)
  end

  # Now we add statements that will provide environment mutation
  # The first one is a statement to do nothing. We can't inherit from Struct
  # with zero-property constructs
  # Doing nothing seems pointless, but can be used to represent a program where
  # execution has completed successfully. Other statements can reduce to
  # a DoNothing after they have completed their work
  class DoNothing
    def to_s
      'do-nothing'
    end

    def inspect
      "«#{self}»"
    end

    def ==(other_statement)
      # This is provided automatically in structs, here we need to create our
      # own
      other_statement.instance_of?(DoNothing)
    end

    def reducible?
        false
    end
  end

  class Assign < Struct.new(:name, :expression)
    def to_s
      "#{name} = #{expression}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

    def reduce(environment)
      if expression.reducible?
        [Assign.new(name, expression.reduce(environment)), environment]
      else
        [DoNothing.new, environment.merge({ name => expression })]
      end
    end
  end

  class StatementMachine < Struct.new(:statement, :environment)
    def step
      self.statement, self.environment = statement.reduce(environment)
    end

    def run
      while statement.reducible?
        step
      end
      [statement, environment]
    end
  end

  def test_statement_machine
    expr = Assign.new(:x, Add.new(Variable.new(:x), Number.new(1)))
    machine = StatementMachine.new(expr, {x: Number.new(2)})
    result, env = machine.run
    assert_equal(DoNothing, result.class)
    assert_equal({x: Number.new(3)}, env)
  end

  class If < Struct.new(:condition, :consequence, :alternative)
    def to_s
      "if (#{condition}) { #{consequence} } else { #{alternative} }"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

    def reduce(environment)
      if condition.reducible?
        [If.new(condition.reduce(environment), consequence, alternative), environment]
      else
        case condition
        when Boolean.new(true)
          [consequence, environment]
        when Boolean.new(false)
          [alternative, environment]
        end
      end
    end
  end

  def test_if
    exp = If.new(Variable.new(:x),
                 Assign.new(:y, Number.new(1)),
                 Assign.new(:y, Number.new(2)))
    env = { x: Boolean.new(true) }
    machine = StatementMachine.new(exp, env)
    res,env = machine.run
    assert_equal(DoNothing, res.class)
    assert_equal(1, env[:y].value)
  end

  def test_if_without_else
    exp = If.new(Variable.new(:x),
                 Assign.new(:y, Number.new(1)),
                 DoNothing.new())
    env = { x: Boolean.new(false) }
    machine = StatementMachine.new(exp, env)
    res,new_env = machine.run
    assert_equal(DoNothing, res.class)
    assert_equal(env, new_env)
  end

  # This is good so far, but we only have the capacity to use single statements.
  # Now we're going to go ahead and create sequences of statements, enabling us
  # to have more than one
  class Sequence < Struct.new(:first, :second)
    def to_s
      "#{first}; #{second}"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

    def reduce(environment)
      case first
      when DoNothing.new
        [second, environment]
      else
        reduced_first, reduced_env = first.reduce(environment)
        [Sequence.new(reduced_first, second), reduced_env]
      end
    end
  end

  def test_reduce_sequence
    expr = Sequence.new(Assign.new(:x, Add.new(Number.new(1), Number.new(1))),
                        Assign.new(:y, Add.new(Variable.new(:x), Number.new(3))))
    env = {}
    machine = StatementMachine.new(expr, env)
    result, end_env = machine.run
    assert_equal(DoNothing, result.class)
    assert_equal({x: Number.new(2), y: Number.new(5)}, end_env)
  end

  # Now we'll implement a looping construct in the form of a while loop.
  # We cannot destructively reduce the while loop expression and body to values
  # because we need to preserve the original exp/statements and be able to run
  # them over and over again.
  # We'll solve that by transforming the while into an if statement containing
  # another while loop,
  # `while (cond) { body }`
  #   will become
  # `if (cond) { body; while (cond) { body } } else { do-nothing }`

  class While < Struct.new(:condition, :body)
    def to_s
      "while (#{condition}) { #{body} }"
    end

    def inspect
      "«#{self}»"
    end

    def reducible?
      true
    end

    def reduce(environment)
      [If.new(condition, Sequence.new(body, self), DoNothing.new), environment]
    end
  end

  def test_while_loop
    expr = While.new(LessThan.new(Variable.new(:x), Number.new(5)),
                     Assign.new(:x, Multiply.new(Variable.new(:x), Number.new(3))))
    env = { x: Number.new(1) }
    machine = StatementMachine.new(expr, env)
    result,new_env = machine.run
    assert_equal(DoNothing.new, result)
    assert_equal({x: Number.new(9)}, new_env)
  end


end
