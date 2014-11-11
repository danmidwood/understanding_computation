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

# The book talks about two possible ways to simulate a NFA, one by traversing
# depth first and a second by traversing breadth first.
# The breadth first approach is interesting, by spawning additional threads at
# each branch point there can be multiple machines reading in paralel.
# In the depth first approach, it sounds like we'll be repeating a lot of the
# processing.
# The machine will be snapshotted at the first branch point, all input from then
# onwards will be retained and, on new input, everything has to be run from the
# branch point, traversing up and down all of the branches until an accept state
# is hit or the traversal is exhauset. On exhausation, the machine will wait for
# the next input character and try the whole thing all over again.

# Nevermind though, the author deems both of these implementations complicated
# and inefficient (I agree), so we're going to build something much simpler.
# And, fortunately, there is an easy way.

# Our strategy is going to be to record the current state as a set of possible
# states, where applying rules for some input maps the set of possible states to
# another set of possible states.
# When we're in a state it doesn't matter how we arrived there, and with this
# strategy there's no simple way to know what it was. To explain further, if our
# input so far gives us more than one path to land in a specific state then that
# state will be a member of our possible states set. The state will only be
# recorded in there once (because it is a set) and it will be without the
# histories to track it back.

# Btw, not that the machine should track things back. To an inputter it's just a
# black box spitting out [accept|not accept] states.

# So, let's add a new Rulebook to handle multiple current states.
require 'set'

class NFARulebook < Struct.new(:rules)
  def next_states(states, character)
    states.flat_map { |state|
      follow_rules_for(state, character)
    }.to_set
  end

  def follow_rules_for(state, character)
    rules_for(state, character).map(&:follow)
  end

  def rules_for(state, character)
    rules.select { |rule| rule.applies_to?(state, character) }
  end
end

class NFARulebookTest < Test::Unit::TestCase
  def test_rulebook
    rulebook = NFARulebook.new([FARule.new(1, 'a', 1), FARule.new(1, 'b', 1),
                                FARule.new(1, 'b', 2), FARule.new(2, 'a', 3),
                                FARule.new(2, 'b', 3), FARule.new(3, 'a', 4),
                                FARule.new(3, 'b', 4)]);

    assert_equal(Set[1, 2], rulebook.next_states(Set[1], 'b'))
    assert_equal(Set[1, 3], rulebook.next_states(Set[1, 2], 'a'))
    assert_equal(Set[1, 2, 4], rulebook.next_states(Set[1, 3], 'b'))

  end
end

# Now we can create a machine
class NFA < Struct.new(:current_states, :accept_states, :rulebook)
  def accepting?
    # This is really nice, the & character performs a set intersection and
    # `any?` tells us whether the result contains anything, i.e. a current state
    # that is also an accept state
    (current_states & accept_states).any?
  end
end

class NFATest < Test::Unit::TestCase
  def test_nfa
    rulebook = NFARulebook.new([FARule.new(1, 'a', 1), FARule.new(1, 'b', 1),
                                FARule.new(1, 'b', 2), FARule.new(2, 'a', 3),
                                FARule.new(2, 'b', 3), FARule.new(3, 'a', 4),
                                FARule.new(3, 'b', 4)]);

    assert_equal(false, NFA.new(Set[1], [4], rulebook).accepting?)
    assert_equal(true, NFA.new(Set[1, 2, 4], [4], rulebook).accepting?)
  end
end


class NFA
  def read_character(character)
    self.current_states = rulebook.next_states(current_states, character)
  end

  def read_string(string)
    string.chars.each do |character|
      read_character(character)
    end
  end
end

class NFACharStringTest < Test::Unit::TestCase
  def test_nfa
    rulebook = NFARulebook.new([FARule.new(1, 'a', 1), FARule.new(1, 'b', 1),
                                FARule.new(1, 'b', 2), FARule.new(2, 'a', 3),
                                FARule.new(2, 'b', 3), FARule.new(3, 'a', 4),
                                FARule.new(3, 'b', 4)]);

    nfa = NFA.new(Set[1], [4], rulebook);
    assert_equal(false, nfa.accepting?)
    nfa.read_character('b')
    assert_equal(false, nfa.accepting?)
    nfa.read_character('a')
    assert_equal(false, nfa.accepting?)
    nfa.read_character('b')
    assert_equal(true, nfa.accepting?)

    # And again, with Strings
    nfa = NFA.new(Set[1], [4], rulebook);
    assert_equal(false, nfa.accepting?)
    nfa.read_string('bbbbb')
    assert_equal(true, nfa.accepting?)


  end
end

# And now let's wrap the machine creation into a "design" that allows us to test
# strings on fresh instances of the machine
class NFADesign < Struct.new(:start_state, :accept_states, :rulebook)
  def accepts?(string)
    to_nfa.tap{ |nfa| nfa.read_string(string) }.accepting?
  end

  def to_nfa
    NFA.new(Set[start_state], accept_states, rulebook)
  end
end

class NFADesignTest < Test::Unit::TestCase
  def test_accepts
    rulebook = NFARulebook.new([FARule.new(1, 'a', 1), FARule.new(1, 'b', 1),
                                FARule.new(1, 'b', 2), FARule.new(2, 'a', 3),
                                FARule.new(2, 'b', 3), FARule.new(3, 'a', 4),
                                FARule.new(3, 'b', 4)]);
    design = NFADesign.new(1, [4], rulebook)
    assert_equal(true, design.accepts?('bab'))
    assert_equal(true, design.accepts?('bbbbb'))
    assert_equal(false, design.accepts?('bbabb'))
  end
end
