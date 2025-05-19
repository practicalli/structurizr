/*
  Practicalli Architecture
*/

/* Constant values */
!constant ORGANISATION_NAME "Practicalli"
!constant GROUP_NAME "Fintech"

workspace "Mock Fintech Startup" "Practicalli Services"  {

  model {
    practicalli = enterprise "${ORGANISATION_NAME} - ${GROUP_NAME}" {

      user = person "User"

      risk = softwareSystem "Risk" {
        shared_services = group "Shared Services Risk" {
          company_info = container "Company WhoIs" "Company search service" "Clojure API" "Clojure Service"
          company_info_database = container "Company WhoIs database" "" "Relational database schema" "Database"
          company_info_search = container "Company Search Aggregator" "Company full-text search index" "Elastic Search Service" "Elastic Search"
          risk_data_providers = container "Risk Data Providers" "Data Provider Service" "Clojure API" "Clojure Servicee"
          risk_data_providers_database = container "Risk Data" "Historic Risk Reports" "Relational database schema" "Database"
        }
        credit = group "Credit Risk" {
          score = container "Credit risk scoring" "Scoring organizations Credit Risk" "Risk Score" "Clojure Servicee"
          score_data = container "Credit Risk Scoring Service database" "" "Relational database schema" "Database"
          assessment = container "Credit Assessment" "Credit risk assessment Service" "Clojure Servicee"
        }

        fraud = group "Fraud Risk" {
          detection = container "Fraud Service" "Detect fraudulent transactions via Fraud Scoring Data Science models" "Http-kit & Reitit" "Clojure Service"
          detection_data = container "Fraud Database" "Historic Fraud detection data" "Relational database schema" "Database"
          ml_model = container "Fraud Models" "Machine learning model service" "ML Models" "AWS SageMaker"
          feature_store_data = container "Feature store" "Pre-calculated feature values" "Key value database" "Database"
          feature_schema_data = container "Feature mapping model/entity" "" "Key value database" "Database"
          manual_review = container "Review Transactions" "Manually review transactions for fraud" "" "WebBrowser"
        }
      }

      transaction = softwareSystem "Transaction" {
        guardian = container "Transaction Guardian" "Transaction monitoring and transaction Screening service" "Clojure API" "Clojure Service"
        guardian_data = container "Transaction Guardian Database" "Historic transaction data" "Relational database schema" "Database"
        limiter = container "Limiter" "Limits Service" "Clojure Kafka Stream" "Clojure Service"
      }

    /* Define Relationships between components */
    user -> transaction "Triggers"

    transaction -> risk "Uses"
    guardian -> guardian_data "Persists"
    guardian -> limiter "Uses"

    detection -> detection_data "Reads and writes to"
    detection -> ml_model "score transaction"
    ml_model -> feature_store_data "Collect features"
    ml_model -> feature_schema_data "Request feature set & model"

    }

  /* Deployment / Infrastructure */

  production = deploymentEnvironment "Production" {
    aws = deploymentNode "Amazon Web Services" "" "" "Amazon Web Services - Cloud" {
      region = deploymentNode "US-East-1" "" "" "Amazon Web Services - Region" {
        route53 = infrastructureNode "Route 53" "" "" "Amazon Web Services - Route 53"
        elb = infrastructureNode "Elastic Load Balancer" "" "" "Amazon Web Services - Elastic Load Balancing"
        autoscalingGroup = deploymentNode "Autoscaling group" "" "" "Amazon Web Services - Auto Scaling" {
          ec2 = deploymentNode "Amazon EC2" "" "" "Amazon Web Services - EC2" {

            webApplicationInstance = containerInstance detection
            elb -> webApplicationInstance "Forwards requests to" "HTTPS"
          }
        }
        rds = deploymentNode "Amazon RDS" "" "" "Amazon Web Services - RDS" {
          mysql = deploymentNode "MySQL" "" "" "Amazon Web Services - RDS MySQL instance" {
            databaseInstance = containerInstance detection_data
          }
        }
        route53 -> elb "Forwards requests to" "HTTPS"
      }
    }
  }
 /* End Of Production Deployment Environment */

  }
  views {
   /* Overall system */
    systemContext risk "EnterpriseView" "Practicalli Enterprise Application" {
      include *
      autoLayout
    }
   /* Entire Risk system */
    container risk riskView "Complete Risk system" {
      include *
      autoLayout
    }
    /* View of shared_services group in risk system */
    container risk sharedServicesView "Services shared across the organisation" {
      include shared_services
      autoLayout
    }
    /* View of fraud_risk group in risk system */
    container risk fraudRiskView "Fraud Risk Services Only" {
      include fraud
      autoLayout
    }
    /* View of credit_risk group in risk system */
    container risk creditRiskView "Credit Risk Services only" {
      include credit
      autoLayout
    }
    /* View of fraud & shared_services group without credit */
    container risk fraudSharedView "Fraud and shared services" {
      include *
      exclude credit
      autoLayout
    }
    container transaction transactionView "Current Transaction system" {
      include *
      autoLayout
    }

    deployment risk "Production" "AmazonWebServicesDeployment" {
      include *
      autolayout lr
      animation {
        route53
        elb
        autoscalingGroup
        webApplicationInstance
        databaseInstance
      }
    }


    /* Theme for views */
    themes default https://static.structurizr.com/themes/amazon-web-services-2022.04.30/theme.json https://raw.githubusercontent.com/practicalli/structurizr/main/themes/practicalli/theme.json

    branding {
      logo https://raw.githubusercontent.com/practicalli/graphic-design/live/logos/practicalli-logo.png
    }
  }
}
