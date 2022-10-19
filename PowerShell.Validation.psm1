<#
.SYNOPSIS
  The Base Validator class is the parent class that all validators inherit from, it is an implementation 
  of the builder pattern to make validation code more readable

.EXAMPLE
  $validator = [BaseValidator]::new()
  $validator.
      AddRule([MustBeSupportedDomainRule]::new("bla@domain.com")).
      AddRule([MustBeSupportedDomainRule]::new("bla2@domain.com")).
      AddRule([MustBeSupportedDomainRule]::new("bla@domain4.com")) | Out-Null

  if ($validator.IsValid()) {
    // Show error messages here
  }

  // code is valid
#>
class BaseValidator {
  hidden $ValidationRuleList = [System.Collections.ArrayList]@()
  hidden $ValidatorResult = $null

  <#
    .SYNOPSIS
    Adds a new validation rule to the validator
  #>
  [BaseValidator] AddRule ([BaseValidationRule]$validationRule) {
      $null = $this.ValidationRuleList.Add($validationRule)
      return $this
  }

  <#
    .SYNOPSIS
    Adds a new validation rule to the validator only if the predicate equals to true
  #>
  [BaseValidator] AddRuleWhen([ScriptBlock]$predicate = {$true}, [BaseValidationRule]$validationRule) {
    # Invoke predicate to get whether it returns true or false
    $predicateResult = Invoke-Command -ScriptBlock $predicate
    
    if ($predicateResult -is [bool] -and $predicateResult -eq $true) {
      $null = $this.ValidationRuleList.Add($validationRule)
    }
    
    return $this
  }

  <#
    .SYNOPSIS
    Loops through a collection and adds a new validation rule for each item to the validator
  #>
  [BaseValidator] AddRuleForEach([array]$arr, $ruleScriptBlock) {
    if ($arr -and $arr.Count -gt 0) {
      foreach ($arrItem in $arr) {
        $validationRule = Invoke-Command -ScriptBlock $ruleScriptBlock -ArgumentList $arrItem

        if ($validationRule -is [BaseValidationRule]) {
          $null = $this.ValidationRuleList.Add($validationRule)
        }
      }
    }
    
    return $this
  }

  <#
    .SYNOPSIS
    Returns a bool indicating whether the validator returns any validation errors
  #>
  [bool] IsValid() {
    if ($this.ValidatorResult) {
      return $this.ValidatorResult.IsValid
    }

    # Validation rules have not been validated before so perform validation of 
    # all rules and return the result
    foreach ($rule in $this.ValidationRuleList) {
        $ruleValidationResult = $rule.Validate()

        if (!$ruleValidationResult.IsValid) {
            $this.ValidatorResult = $ruleValidationResult
            return $false
        }
    }

    $this.ValidatorResult = [ValidationResult]::new()
    return $true
  }

  <#
    .SYNOPSIS
    Returns the first error message in the validator
  #>
  [string] GetErrorMessage() {
      return $this.ValidatorResult.ErrorMessage
  }
  
  <#
    .SYNOPSIS
    Returns a bool indicating whether the failed validation rules return any critical errors
  #>
  [bool] HasCriticalErrors() {
      return $this.ValidatorResult.IsCriticalError
  } 
}

<#
.SYNOPSIS
  The Base Validation Rule class is the parent class that all validation rules inherit from, every class 
  inheriting from this class must override the Validate function
#>
class BaseValidationRule {

  BaseValidationRule() {
  }

  [ValidationResult] Validate() {
      return $null
  }
}

<#
.SYNOPSIS
  The Validation Result class holds data about the result of a validation rule
#>
class ValidationResult {

  [bool]$IsValid
  [string]$ErrorMessage
  [bool]$IsCriticalError

  ValidationResult() {
    $this.IsValid = $true
  }
}

<#
.SYNOPSIS
  The SuccessValidationResult class is returned from a validation rule if the validation passed
#>
class SuccessValidationResult: ValidationResult {
  SuccessValidationResult(): Base() {
    $this.IsValid = $true
  }
}

<#
.SYNOPSIS
  The FailedValidationResult class is returned from a validation rule if the validation does not pass
#>
class FailedValidationResult: ValidationResult {

  FailedValidationResult([string]$errorMessage): Base() {
    $this.IsValid = $false
    $this.ErrorMessage = $errorMessage
    $this.IsCriticalError = $false
  }

  FailedValidationResult([string]$errorMessage, [bool]$isCriticalError): Base() {
    $this.IsValid = $false
    $this.ErrorMessage = $errorMessage
    $this.IsCriticalError = $isCriticalError
  }
}

<#
.SYNOPSIS
  The MustBeSupportedDomainRule validates that an e-mail address' domain is an accepted domain

.EXAMPLE
  $validator.AddRule([MustBeSupportedDomainRule]::new("user@domain.com"))

#>
class MustBeFilledRule: BaseValidationRule {
  [string]$text
  MustBeSupportedDomainRule([string]$Text): Base() {
    $this.text = $Text
  }

  # Perform validation checks
  [ValidationResult] Validate() {

      if ([string]::IsNullOrEmpty($this.text)) {
          return [FailedValidationResult]::new(
            "Text '$($this.text)' has a value", $true
          )
      }

      return [SuccessValidationResult]::new()
  }
}
