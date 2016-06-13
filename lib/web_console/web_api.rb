module WebConsole
  class WebAPI
    # auto completion
    def self.complete(id, s)
      if session = Session.find(id)
        session.eval('local_variables')
      end
    end
  end
end
