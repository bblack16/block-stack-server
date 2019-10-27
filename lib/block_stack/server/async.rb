module BlockStack
  class Server < Sinatra::Base

    bridge_method :task_vault, :task_vault=, :in, :after, :later, :at, :every, :cron

    def self.task_vault
      @task_vault ||= TaskVault::Server.prototype
    end

    def self.task_vault=(server)
      raise TypeException, 'Must be a TaskVault::Server' unless server.is_a?(TaskVault::Server)
      @task_vault = server
    end


    def self.in(time, opts = {}, &block)
      task_vault.in(time, opts, &block)
    end

    def self.after(time, opts = {}, &block)
      task_vault.after(time, opts, &block)
    end

    def self.later(opts = {}, &block)
      task_vault.now(opts, &block)
    end

    def self.at(time, opts = {}, &block)
      task_vault.at(time, opts, &block)
    end

    def self.every(time, opts = {}, &block)
      task_vault.every(time, opts, &block)
    end

    def self.cron(time, opts = {}, &block)
      task_vault.cron(time, opts, &block)
    end

  end
end
