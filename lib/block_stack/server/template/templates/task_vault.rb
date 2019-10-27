module BlockStack

  add_template(:home, :task_vault_api, :get_api, '/task_vault', type: :route) do
    {
      running: task_vault.running?,
      healthy: task_vault.healthy?,
      components: task_vault.components.map do |component|
        {
          id: component.id,
          name: component.name,
          class: component.class.to_s,
          running: component.running?
        }
      end,
      links: {
        components: absolute_link(env['PATH_INFO'] + '/components'),
        tasks: absolute_link(env['PATH_INFO'] + '/tasks')
      }
    }
  end

  add_template(:components, :task_vault_api, :get_api, '/task_vault/components', type: :route) do
    components = task_vault.components.map do |component|
      {
        id: component.id,
        name: component.name,
        class: component.class.to_s,
        running: component.running?,
        link: absolute_link(env['PATH_INFO'] + "/#{Rack::Utils.escape(component.id)}"),
        alternate_link: absolute_link(env['PATH_INFO'] + "/#{Rack::Utils.escape(component.name)}")
      }
    end
    build_api_response(components, env['PATH_INFO'], params)
  end

  add_template(:component, :task_vault_api, :get_api, '/task_vault/components/:id', type: :route) do
    component = task_vault.components.find do |component|
      component.id == params[:id] || component.name == params[:id]
    end
    puts component
    halt(404, { status: :error, message: "No component was found in task vault with an ID or #{params[:id]}" }) unless component
    build_api_response(component.serialize, env['PATH_INFO'], params)
  end

  add_template(:tasks, :task_vault_api, :get_api, '/task_vault/tasks', type: :route) do
    tasks = task_vault.component_of(TaskVault::Overseer).tasks.map do |task|
      {
        id: task.id,
        name: task.name,
        status: task.status,
        type: task.type,
        link: absolute_link(env['PATH_INFO'] + "/#{task.id}")
      }
    end
    build_api_response(tasks, env['PATH_INFO'], params)
  end

  add_template(:tasks, :task_vault_api, :get_api, '/task_vault/tasks/:id', type: :route) do
    task = task_vault.component_of(TaskVault::Overseer).find(params[:id])
    halt(404, { status: :error, message: "No task was found with an id of #{params[:id]}" }) unless task
    build_api_response(task.serialize, env['PATH_INFO'], params)
  end

  add_template(:tasks_history, :task_vault_api, :get_api, '/task_vault/tasks/:id/history', type: :route) do
    task = task_vault.component_of(TaskVault::Overseer).find(params[:id])
    halt(404, { status: :error, message: "No task was found with an id of #{params[:id]}" }) unless task
    build_api_response(task.message_queue.history.map(&:serialize), env['PATH_INFO'], params)
  end

end
