module BlockStack
  def self.in(time, opts = {}, &block)
    TaskVault.in(time, opts, &block)
  end

  def self.after(time, opts = {}, &block)
    TaskVault.after(time, opts, &block)
  end

  def self.later(opts = {}, &block)
    TaskVault.now(opts, &block)
  end

  def self.at(time, opts = {}, &block)
    TaskVault.at(time, opts, &block)
  end

  def self.every(time, opts = {}, &block)
    TaskVault.every(time, opts, &block)
  end

  def self.cron(time, opts = {}, &block)
    TaskVault.cron(time, opts, &block)
  end
end
