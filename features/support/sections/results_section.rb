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
        }
      }
    end

    private

    attr_reader :panel_elements

    def jira_element(panel_element, klass)
      panel_element.first(".#{klass}")
    end
  end
end
