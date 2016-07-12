module WebConsole
  # A session lets you persist an +Evaluator+ instance in memory associated
  # with multiple bindings.
  #
  # Each newly created session is persisted into memory and you can find it
  # later by its +id+.
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

      # Create a Session from an binding or exception in a storage.
      #
      # The storage is expected to respond to #[]. The binding is expected in
      # :__web_console_binding and the exception in :__web_console_exception.
      #
      # Can return nil, if no binding or exception have been preserved in the
      # storage.
      def from(storage)
        if exc = storage[:__web_console_exception]
          new(ExceptionMapper.new(exc))
        elsif binding = storage[:__web_console_binding]
          new([binding])
        end
      end
    end

    # An unique identifier for every REPL.
    attr_reader :id

    def initialize(bindings)
      @id = SecureRandom.hex(16)
      @bindings = bindings

      switch_binding_to 0
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
      @evaluator = Evaluator.new(@current_binding = @bindings[index.to_i])
    end

    # Returns context of the current binding
    def context(obj)
      ( object_name?(obj) ? context_of(obj) : global_context ).flatten
    end

    private

      def object_name?(s)
        s.is_a?(String) && !s.empty? && !s.match(/[^a-zA-Z0-9\@\$\.\:]/)
      end

      def context_eval(cmd)
        @current_binding.eval(cmd) rescue []
      end

      def global_context
        [
          'global_variables',
          'local_variables',
          'instance_variables',
          'instance_methods',
          'class_variables',
          'methods',
          'Object.constants',
          'Kernel.methods',
        ].map { |cmd| context_eval(cmd) }
      end
      
      def context_of(o)
        [
          context_eval("#{o}.methods").map { |m| "#{o}.#{m}" },
          context_eval("#{o}.constants").map { |c| "#{o}::#{c}" },
        ]
      end

      def store_into_memory
        inmemory_storage[id] = self
      end
  end
end
