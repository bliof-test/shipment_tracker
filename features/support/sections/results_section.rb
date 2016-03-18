module Sections
  class ResultsSection
    def initialize(panel_elements)
      @panel_elements = panel_elements
    end

    def items
      panel_elements.map { |panel_element|
        {
          'Jira Key' => jira_element(panel_element, 'key')&.text,
          'Summary' =>  jira_element(panel_element, 'summary')&.text,
          'Description' => jira_element(panel_element, 'description')&.text,
          'Deploys' => jira_elements(panel_element, 'deploy').map {|deploy_element| deploy_element.text},
        }
      }
    end

    private

    attr_reader :panel_elements

    def jira_element(panel_element, klass)
      panel_element.first(".#{klass}")
    end

    def jira_elements(panel_element, klass)
      panel_element.all(".#{klass}")
    end
  end
end
