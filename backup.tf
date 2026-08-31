resource "aws_backup_vault" "main" {
  name = "${var.project_name}-backup-vault"
}

resource "aws_backup_plan" "main" {
  name = "${var.project_name}-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.main.name
    schedule          = "cron(0 18 * * ? *)"

    lifecycle {
      delete_after = 7
    }
  }
}

resource "aws_backup_selection" "ec2" {
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${var.project_name}-ec2-selection"
  plan_id      = aws_backup_plan.main.id

  resources = [
    aws_instance.web.arn
  ]
}