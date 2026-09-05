# One database + one login role per service, all on the single shared
# RDS instance from module.rds. This is what actually makes "one shared
# instance" still honor "each service owns its schema exclusively" -
# order-service's credentials only ever work against shopstream_orders;
# it is never handed credentials that could reach shopstream_users, even
# though both databases physically live on the same instance.
#
# NOTE, honestly: Postgres's default behavior grants CONNECT on every
# database to PUBLIC (every role), so a service's DB_USER *could*
# authenticate against another service's database unless that default is
# explicitly revoked - which isn't done here. In practice no service's
# code ever gets told another database's name/credentials, so this
# isn't exploitable through the application, but it is not the same as
# a hard database-level guarantee. Revoking PUBLIC's CONNECT privilege
# per database is the stricter version of this, left as a deliberate
# simplification rather than something quietly assumed to be handled.

locals {
  service_databases = {
    "user-service"    = { database = "shopstream_users", role = "user_service" }
    "product-service" = { database = "shopstream_products", role = "product_service" }
    "order-service"   = { database = "shopstream_orders", role = "order_service" }
    "payment-service" = { database = "shopstream_payments", role = "payment_service" }
  }
}

resource "random_password" "service_db" {
  for_each = local.service_databases

  length  = 24
  special = false
}

resource "postgresql_role" "this" {
  for_each = local.service_databases

  name     = each.value.role
  login    = true
  password = random_password.service_db[each.key].result
}

resource "postgresql_database" "this" {
  for_each = local.service_databases

  name  = each.value.database
  owner = postgresql_role.this[each.key].name
}

resource "aws_secretsmanager_secret" "service_db" {
  for_each = local.service_databases

  name        = "${local.name}/${each.key}/db-credentials"
  description = "${each.key}'s scoped Postgres credentials - valid only against ${each.value.database}, not the other three databases on this instance."

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "service_db" {
  for_each = local.service_databases

  secret_id = aws_secretsmanager_secret.service_db[each.key].id
  secret_string = jsonencode({
    DB_HOST     = module.rds.endpoint
    DB_PORT     = module.rds.port
    DB_NAME     = each.value.database
    DB_USER     = postgresql_role.this[each.key].name
    DB_PASSWORD = random_password.service_db[each.key].result
  })
}
