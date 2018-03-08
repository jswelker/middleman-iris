Feature: Extensions to Middleman::Sitemap::Resource class

  Scenario: something
    Given the Server is running at "default-app"
    When I go to "/index.html"
    Then I should see "Collection: Test Collection"
    And I should see "Resource: Just Some Random Page"
