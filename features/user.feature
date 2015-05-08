Feature: user
  Scenario: show
    When I go to /user/no_regret_y
    Then I should see "hoo"
