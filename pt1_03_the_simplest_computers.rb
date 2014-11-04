# Deterministic Finite Automata

# A finite state machine or finite automaton is a drastically simplified model
# of a computer that eshews the complexities of ram and storage, prefering to be
# easy to read, understand and reason about.
# And also easier to implement, thankfully for us.

# States, Rules, and Input

# A FSM has no permanent storage and virtually no RAM, only being a machine with
# a few states and the ability to track the current state. Each FSM is backed by
# a hardcoded collection of rules that determine how it should move from one
# state to another in response to input.

# A FSM will have a start start state and accept inputs, the inputs and the
# rules for the current state will determine the next state.

# FSMs act as a black box, with information about the current state assumed to
# be internal only to the FSM. A FSM switching between states looks exactly the
# same from the outside as one that is doing nothing.

# Output

# To make an FSM useful to us we should have it output something. FSMs have a
# rudimentary way to produce output through accept states. An accept state
# indicates that the input has been accepted. We can view this as though the FSM
# is producing a boolean, true when the end state is an accept state and false
# otherwise.

# Determinism

# So far we've seen FSMs that are solely deterministic, whatever state it's in
# and whatever characters it reads, the outcome state will always be certain.
# Determinism is maintained by two constraints:
## No contradictions: Leading to ambiguous moves. In practice, this means that
# no state can have more than one rule for the same input
## No omissions: There are no states where the next move is unknown. Each and
# every state should have at least one rule for each possible input character

# In conclusion, the constraints mean that the machine must have exactly one
# rule for each combination of state and input.
# The technical term for a FSM that obeys these constraints is a `deterministic
# finite automaton` or DFA.

# Simulation

# Here we build a DFA, or a simulation of one.

require 'test/unit'

class FARule < Struct.new(:state, :character, :next_state)
  def applies_to?(state, character)
    self.state == state && self.character == character
  end

  def follow
    next_state
  end

  def inspect
    "#<FARule #{state.inspect} --#{character}--> #{next_state.inspect}>"
  end
end

class DFARulebook < Struct.new(:rules)
  def next_state(state, character)
    rule_for(state, character).follow
  end

  def rule_for(state, character)
    rules.detect { |rule| rule.applies_to?(state, character) }
  end
end




class DFARulebookTest < Test::Unit::TestCase
  def test_rulebook
    rulebook = DFARulebook.new([FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
                                FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
                                FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)]);

    assert_equal(2, rulebook.next_state(1, 'a'))
    assert_equal(1, rulebook.next_state(1, 'b'))
    assert_equal(3, rulebook.next_state(2, 'b'))

  end
end


class DFA < Struct.new(:current_state, :accept_states, :rulebook)
  def accepting?
    accept_states.include?(current_state)
  end

  def read_character(character)
    self.current_state = rulebook.next_state(current_state, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class DFATest < Test::Unit::TestCase

  def test_dfa
    rulebook = DFARulebook.new([FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
                                FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
                                FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)]);

    dfa = DFA.new(1, [3], rulebook)

    assert_equal(false, dfa.accepting?)

    dfa.read_character('b')
    assert_equal(false, dfa.accepting?)

    3.times do dfa.read_character('a') end;
    assert_equal(false, dfa.accepting?)

    dfa.read_character('b')
    assert_equal(true, dfa.accepting?)
  end

  def test_string_input
    rulebook = DFARulebook.new([FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
                                FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
                                FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)]);

    dfa = DFA.new(1, [3], rulebook)
    assert_equal(false, dfa.accepting?)

    dfa.read_string('baaab')
    assert_equal(true, dfa.accepting?)

  end
end

class DFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def to_dfa
    DFA.new(start_state,accept_states, rulebook)
  end

  def accepts?(string)
    to_dfa.tap { |dfa| dfa.read_string(string) }.accepting?
  end
end

class DFADesignTest < Test::Unit::TestCase
  def test_dfa_design
    rulebook = DFARulebook.new([FARule.new(1, 'a', 2), FARule.new(1, 'b', 1),
                                FARule.new(2, 'a', 2), FARule.new(2, 'b', 3),
                                FARule.new(3, 'a', 3), FARule.new(3, 'b', 3)]);
    dfa_design = DFADesign.new(1, [3], rulebook)
    assert_equal(false, dfa_design.accepts?('a'))

    assert_equal(false, dfa_design.accepts?('baa'))

    assert_equal(true, dfa_design.accepts?('baba'))

  end
end


# Nondeterministic Finite Automata
# uh-oh..

# Here we see a flaw in deterministic automatons. If we want a machine that
# accepts when the third character matches (in the example a 'b') then that is
# simply achieveable. But if we want to build a a machine that accepts when the
# third character from the end is a `b` then that is something we cannot
# predict.

# If we allow the rulebook to contain non-1 rules against a given state and
# input then we can achieve the goal but by sacrificing our determinism.

# Note: at this point I'm assuming that we sacrifice our determinism by allowing
# our machine to be in more than one state at once. But I do think it will need
# to "collapse" into a single state for acceptance, and that should be determin-
# -istic based on the input. We will see..
