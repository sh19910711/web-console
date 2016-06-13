module WebConsole
  class WebAPI
    # auto completion
    def self.complete(id, start_with)
      if session = Session.find(id)
        session.eval('local_variables', :itself).map(&:to_s).select do |key|
          key.start_with?(start_with)
        end
      end
    end
  end
end
