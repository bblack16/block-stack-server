module BlockStack

  add_template(:welcome, :block_stack_api, :get_api, '/', type: :route) do
    {
      message: params[:message] || "Welcome to #{self.class.to_s}",
      application: self.class.to_s,
      system: {
        block_stack_version: BlockStack::VERSION,
        ruby: RUBY_VERSION,
        time: Time.now.to_f,
        os: BBLib::OS.os
      }
    }
  end

  add_template(:routes, :block_stack_api, :get_api, '/routes', type: :route) do
    self.class.route_map
  end

  add_template(:time, :block_stack_api, :get_api, '/time', type: :route) do
    { time: params[:time_format] ? Time.now.strftime(params[:time_format]) : Time.now.to_f }
  end
end
