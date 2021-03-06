Feature: TestSystem.False

  Background:
    Given the type under test is False

  Scenario: Against false

    Given I dress JSON's 'false'
    Then the result should be a representation for False
    Then the result should be a representation for Boolean
    And the result should be the Boolean false

  Scenario: Against true

    Given I dress JSON's 'true'
    Then it should be a TypeError as:
      | message               |
      | Invalid False: `true` |

  Scenario: Against null

    Given I dress JSON's 'null'
    Then it should be a TypeError as:
      | message               |
      | Invalid False: `null` |

  Scenario: Against an arbitrary value

    Given I dress JSON's '12'
    Then it should be a TypeError as:
      | message             |
      | Invalid False: `12` |
