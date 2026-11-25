// DEMO QA job: demo-qa-job  (runs on the QA Jenkins, EC2-B)
// Tests the running demo app over HTTP, publishes the JUnit report and (optionally) e-mails the result.
pipeline {
    agent any

    parameters {
        string(name: 'APP_URL', defaultValue: 'http://EC2-A-IP:8085', description: 'Application URL to test (EC2-A). Replace EC2-A-IP with the real IP.')
        booleanParam(name: 'SEND_EMAIL', defaultValue: false, description: 'Send an e-mail with the result (needs SMTP set up in Jenkins, see guide part 10)')
        string(name: 'EMAIL_TO', defaultValue: 'you@example.com', description: 'E-mail recipient (only used when SEND_EMAIL is ticked)')
    }

    options {
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Check application is reachable') {
            steps {
                sh '''
                    case "$APP_URL" in
                      *EC2-A-IP*) echo "APP_URL still contains the placeholder EC2-A-IP. Run with the real URL."; exit 1 ;;
                    esac
                    echo "Testing application: $APP_URL"
                    curl -fsS --retry 5 --retry-delay 5 --retry-connrefused "$APP_URL/health"
                    echo
                '''
            }
        }

        stage('Run tests') {
            steps {
                sh '''
                    chmod +x tests/run_tests.sh
                    ./tests/run_tests.sh
                '''
            }
        }
    }

    post {
        always {
            // JUnit plugin: shows the Test Result trend/page on the build
            junit allowEmptyResults: true, testResults: 'reports/*.xml'
            archiveArtifacts artifacts: 'reports/**', allowEmptyArchive: true
            script {
                if (params.SEND_EMAIL) {
                    emailext(
                        to: params.EMAIL_TO,
                        subject: "[Demo QA] ${currentBuild.currentResult}: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: "Application: ${params.APP_URL}\nResult: ${currentBuild.currentResult}\nBuild: ${env.BUILD_URL}\nTests: ${env.BUILD_URL}testReport/",
                        attachmentsPattern: 'reports/junit.xml'
                    )
                }
            }
        }
        success { echo 'All demo tests passed.' }
        failure { echo 'Some demo tests failed - open "Test Result" on the build page.' }
    }
}
