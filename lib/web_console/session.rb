module WebConsole
  # A session lets you persist wrap an +Evaluator+ instance in memory
  # associated with multiple bindings.
  #
  # Each newly created session is persisted into memory and you can find it
  # later its +id+.
  #
  # A session may be associated with multiple bindings. This is used by the
  # error pages only, as currently, this is the only client that needs to do
  # that.
  class Session
    cattr_reader :inmemory_storage
    @@inmemory_storage = {}

    class << self
      # Finds a persisted session in memory by its id.
      #
      # Returns a persisted session if found in memory.
      # Raises NotFound error unless found in memory.
      def find(id)
        inmemory_storage[id]
      end

      # Create a Session from an exception.
      def from_exception(exc)
        new(exc.bindings)
      end

      # Create a Session from a single binding.
      def from_binding(binding)
        new(binding)
      end
    end

    # An unique identifier for every REPL.
    attr_reader :id

    def initialize(bindings)
      @id = SecureRandom.hex(16)
      @bindings = Array(bindings)
      @last_index = 0
      @evaluator = Evaluator.new(@bindings[@last_index])

      store_into_memory
    end

    # Evaluate +input+ on the current Evaluator associated binding.
    #
    # Returns a string of the Evaluator output.
    def eval(input)
      @evaluator.eval(input)
    end

    # Switches the current binding to the one at specified +index+.
    #
    # Returns nothing.
    def switch_binding_to(index)
      @last_index = index.to_i
      @evaluator = Evaluator.new(@bindings[@last_index])
    end

    def last_binding
      @bindings[@last_index]
    end

    def context
      {
        local_variables: local_variables,
      }
    end

    private

      def local_variables
        last_binding.local_variables.reduce({}) do |hash, key|
          hash[key] = {
            key: key,
            value: last_binding.eval(key.to_s),
          }
          hash
        end
      end

      def store_into_memory
        inmemory_storage[id] = self
      end
  end
end
