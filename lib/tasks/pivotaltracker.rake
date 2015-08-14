namespace :pivotaltracker do
  desc "Fetches data from Pivotal Tracker"
  task fetch_data: :environment do

    project_id = ENV['project_id'] or raise 'No project_id specified'
    api_token = ENV['api_token'] or raise 'No api_token specified'
    story_type = ENV['story_type'] # optional

    # fetch stories for project
    client = PivotalTracker::Client.new(api_token)
    stories = client.project_stories(project_id: project_id, type: story_type)

    headers = ['Name', 'Size', 'Prioritized For Grooming', 'Ready to Pick Up', 'Started', 'Ready to Demo', 'Under Test', 'Merged to Master', 'Released', 'Accepted']
    rows = stories.map do |story|
      row = {
        'Name' => story['name'],
        'Size' => story['estimate'],
        'Prioritized For Grooming' => nil,
        'Ready to Pick Up' => nil,
        'Started' => nil,
        'Ready to Demo' => nil,
        'Under Test' => nil,
        'Merged to Master' => nil,
        'Released' => nil,
        'Accepted' => nil
      }

      row['Prioritized For Grooming'] = client.story_activities(project_id: project_id,
                                                        story_id: story['id'],
                                                        kind: 'story_update_activity',
                                                        message_regex: /estimated this (feature|bug)/).try(:first).try(:[], 'occurred_at')
      row['Ready to Pick Up'] = client.story_activities(project_id: project_id,
                                                        story_id: story['id'],
                                                        kind: 'story_move_activity',
                                                        message_regex: /moved this story before '.*Prioritized for Grooming.*'/).try(:first).try(:[], 'occurred_at')
      row['Started'] = client.story_activities(project_id: project_id,
                                               story_id: story['id'],
                                               kind: 'story_update_activity',
                                               message_regex: /started this (feature|bug)/).try(:first).try(:[], 'occurred_at')
      row['Ready to Demo'] = client.story_activities(project_id: project_id,
                                                     story_id: story['id'],
                                                     kind: 'story_move_activity',
                                                     message_regex: /moved this story before '.*Under Review.*'/).try(:first).try(:[], 'occurred_at')
      row['Under Test'] = client.story_activities(project_id: project_id,
                                                  story_id: story['id'],
                                                  kind: 'story_move_activity',
                                                  message_regex: /moved this story before '.*Ready to Demo.*'/).try(:first).try(:[], 'occurred_at')
      row['Merged to Master'] = client.story_activities(project_id: project_id,
                                                        story_id: story['id'],
                                                        kind: 'story_move_activity',
                                                        message_regex: /moved this story before '.*Verified on Branch.*'/).try(:first).try(:[], 'occurred_at')
      row['Released'] = client.story_activities(project_id: project_id,
                                                story_id: story['id'],
                                                kind: 'story_move_activity',
                                                message_regex: /moved this story before '.*Awaiting Release.*'/).try(:first).try(:[], 'occurred_at')

      row['Accepted'] = client.story_activities(project_id: project_id,
                                                story_id: story['id'],
                                                kind: 'story_update_activity',
                                                message_regex: /accepted this (feature|bug)/).try(:first).try(:[], 'occurred_at')
      row
    end

    puts "#{headers.map{|h| "\"#{h}\""}.join(',')}"
    rows.each do |row|
      puts ["#{row['Name']}",
        "#{row['Size']}",
        "#{formatted_date(row['Prioritized For Grooming'])}",
        "#{formatted_date(row['Ready to Pick Up'])}",
        "#{formatted_date(row['Started'])}",
        "#{formatted_date(row['Ready to Demo'])}",
        "#{formatted_date(row['Under Test'])}",
        "#{formatted_date(row['Merged to Master'])}",
        "#{formatted_date(row['Released'])}",
        "#{formatted_date(row['Accepted'])}"
       ].map { |r| "\"#{r}\""}.join(',')
    end
  end

  private

  def formatted_date(date)
    date.present? ? DateTime.parse(date).strftime('%Y/%m/%d') : ''
  end
end
