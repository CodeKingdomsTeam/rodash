pipeline {

	agent any

	options {
		ansiColor('xterm')
	}

	stages {

		stage('Setup') {
			steps {
				sh './setup.sh'
			}
		}

		stage('Luacheck') {
			steps {
				sh './tools/luacheck.sh'
			}
			post {
				failure {
					githubNotify description: 'Luacheck failed',  status: 'FAILURE', context: 'luacheck'
				}
				success {
					githubNotify description: 'Luacheck passed.',  status: 'SUCCESS', context: 'luacheck'
				}
			}
		}

		stage('Code style check') {
			steps {
				sh './tools/checkFormat.sh'
			}
			post {
				failure {
					githubNotify description: 'Code style check failed',  status: 'FAILURE', context: 'codestyle'
				}
				success {
					githubNotify description: 'Code style check passed.',  status: 'SUCCESS', context: 'codestyle'
				}				
			}
		}

		stage('Tests') {
			steps {
				sh 'rm -f luacov.stats.* luacov.report.* testReport.xml cobertura.xml && ./test.sh --verbose --coverage --output junit > testReport.xml && ./lua_install/bin/luacov-cobertura -o cobertura.xml'
			}
			post {
				failure {
					githubNotify description: 'Tests failed',  status: 'FAILURE', context: 'tests'
				}
				success {
					githubNotify description: 'Tests passed.',  status: 'SUCCESS', context: 'tests'
				}
			}
		}

		stage('Record Coverage') {
			when { branch 'master' }
			steps {
				script {
					currentBuild.result = 'SUCCESS'
				}
				step([$class: 'MasterCoverageAction', scmVars: [GIT_URL: env.GIT_URL]])
			}
		}

		stage('PR Coverage to Github') {
			when { allOf {not { branch 'master' }; expression { return env.CHANGE_ID != null }} }
			steps {
				script {
					currentBuild.result = 'SUCCESS'
				 }
				step([$class: 'CompareCoverageAction', scmVars: [GIT_URL: env.GIT_URL]])
			}
		}
	}

	post {
		always {
			junit "testReport.xml"
			cobertura coberturaReportFile: 'cobertura.xml'
		}
		failure {
			githubNotify description: 'Build failed.',  status: 'ERROR'
		}
		unstable {
			githubNotify description: 'Status checks failed.',  status: 'FAILURE'
		}
		success {
			githubNotify description: 'Status checks passed.',  status: 'SUCCESS'
		}
	}

}
