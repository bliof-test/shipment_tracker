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
          'Deploys' => jira_elements(panel_element, 'deploy').map(&:text),
        }
      }
    end

    private

    attr_reader :panel_elements

    def jira_element(panel_element, css_class)
      panel_element.first(".#{css_class}")
    end

    def jira_elements(panel_element, css_class)
      panel_element.all(".#{css_class}")
    end
  end
end
