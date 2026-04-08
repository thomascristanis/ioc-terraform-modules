output "budget_name" {
  description = "Name of the AWS Budget created for daily cost alerting."
  value       = aws_budgets_budget.daily.name
}
