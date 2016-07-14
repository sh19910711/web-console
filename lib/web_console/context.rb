module WebConsole
  class Context
    def initialize(binding)
      @binding = binding
    end

    def of(objpath)
      if objpath.is_a?(String) and not objpath.empty?
        [
          eval("#{objpath}.methods").map { |m| "#{objpath}.#{m}" },
          eval("#{objpath}.constants").map { |c| "#{objpath}::#{c}" },
        ]
      else
        global
      end.flatten
    end

    private

      def global
        [
          'global_variables',
          'local_variables',
          'instance_variables',
          'instance_methods',
          'class_variables',
          'methods',
          'Object.constants',
          'Kernel.methods',
        ].map { |cmd| eval(cmd) }
      end

      def eval(cmd)
        @binding.eval(cmd) rescue []
      end
  end
end
