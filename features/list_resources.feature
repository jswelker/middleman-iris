Feature: Extensions to Middleman::Sitemap::Resource class

  Scenario: List collections and resources on the home page
    Given the Server is running at "default-app"
    When I go to "/index.html"
    Then I should see "Collection: Test Collection"
    And I should see "Collection: Test Subcollection 1"
    And I should see "Collection: Test Subcollection 2"
    And I should see "Resource: Just Some Random Page"
    And I should see "Resource: some_tiff_image"
