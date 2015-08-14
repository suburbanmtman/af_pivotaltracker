module PivotalTracker
  class Client

    def initialize(api_token)
      @api_token = api_token
      @cache = {}
    end

    def project_stories(project_id:, type: nil)
      uri = "projects/#{project_id}/stories"
      uri += "?filter=story_type%3A#{type}" if type.present?
      request(uri)
    end

    def story_activities(project_id:, story_id:, kind: nil, message_regex: nil)
      results = request("projects/#{project_id}/stories/#{story_id}/activity")
      results.select! { |result| result['kind'] == kind } if kind.present?
      results.select! { |result| result['message'] =~ message_regex } if message_regex.present?
      results
    end

    private

    def from_cache(uri)
      @cache[uri].try(:clone)
    end

    def store_cache(uri, data)
      @cache[uri] = data.clone
      data
    end

    def request(uri)
      from_cache(uri) or store_cache(uri, parse_response(connection(uri).get))
    end

    PIVOTALTRACKER_SERVICE_URL = 'https://www.pivotaltracker.com/services/v5/'

    def connection(uri)
      RestClient::Resource.new("#{PIVOTALTRACKER_SERVICE_URL}#{uri}", options)
    end

    def parse_response(response_str)
      JSON.parse(response_str)
    end

    def options
      {
        headers: {
          'X-TrackerToken' => @api_token
        }
      }
    end
  end
end
