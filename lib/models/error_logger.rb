module BarkestLcd
  module ErrorLogger

    public

    ##
    # Contains the last 100 errors that have occurred in this instance.
    def error_history
      @error_history ||= []
    end

    protected

    def log_error(code, msg)
      HIDAPI.debug "Encountered error (#{code.to_s(16).rjust(8, '0')}) #{msg}"
      error_history << [ code, msg, Time.now ]
      error_history.delete_at(0) while error_history.count > 100
    end

  end
end
