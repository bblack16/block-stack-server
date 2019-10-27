module BlockStack
  module Helpers
    module Server
      def format
        formatter = pick_formatter(request, params)
        formatter ? [formatter.format].flatten.first : :html
      end

      def absolute_link(path, params = {})
        base = [config.app_address.uncapsulate('/'), path.uncapsulate('/')].join('/')
        query = Rack::Utils.build_query(params.reject { |k, v| v.nil? })
        return base if query.empty?
        [base, query].join('?')
      end

      def build_api_response(data, path, params, opts = {})
        path = path.sub(/\.#{Regexp.escape(params[:format])}$/ , '') if params[:format]
        {
          _links: build_api_links(path, {}, opts),
          data: data
        }
      end

      def build_api_links(path, params, opts = {})
        { self: absolute_link(path, params) }.tap do |links|
          if opts[:page] && opts[:page_count]
            links[:first] = absolute_link(path, params.merge(page: 1))
            links[:prev] = (opts[:page] == 1 ? nil : absolute_link(path, params.merge(page: opts[:page] - 1)))
            links[:next] = (opts[:page] >= opts[:page_count] ? nil : absolute_link(path, params.merge(page: opts[:page] + 1)))
            links[:last] = absolute_link(path, params.merge(page: opts[:page_count]))
          end
        end
      end
    end
  end
end
