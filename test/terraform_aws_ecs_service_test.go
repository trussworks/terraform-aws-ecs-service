package test

import (
	"crypto/tls"
	"fmt"
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
)

func TestTerraformAwsEcsServiceNoLoadBalancer(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/no-load-balancer")

	ecsServiceName := fmt.Sprintf("terratest-simple-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-west-2"
	vpcAzs := aws.GetAvailabilityZones(t, awsRegion)[:3]

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"test_name": ecsServiceName,
			"vpc_azs":   vpcAzs,
			"region":    awsRegion,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Step through cluster and task to retrieve public IP of instance
	tasksOutput := GetTasks(t, awsRegion, ecsServiceName)
	singleTaskEni := GetEni(t, awsRegion, ecsServiceName, tasksOutput.TaskArns)
	publicIP := GetPublicIP(t, awsRegion, []string{*singleTaskEni})

	testURL8080 := fmt.Sprintf("http://%v:8080", *publicIP)
	testURL8081 := fmt.Sprintf("http://%v:8081", *publicIP)
	expectedText := "Hello, world!"
	tlsConfig := tls.Config{
		MinVersion: tls.VersionTLS13,
	}
	maxRetries := 2
	timeBetweenRetries := 30 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		testURL8080,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
	http_helper.HttpGetWithRetry(
		t,
		testURL8081,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
}

func TestTerraformAwsEcsServiceAlb(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load-balancer")

	ecsServiceName := fmt.Sprintf("terratest-simple-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-west-2"
	vpcAzs := aws.GetAvailabilityZones(t, awsRegion)[:3]

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"test_name":     ecsServiceName,
			"vpc_azs":       vpcAzs,
			"region":        awsRegion,
			"associate_alb": true,
			"associate_nlb": false,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lbDNSName := terraform.Output(t, terraformOptions, "lb_dns_name")
	testURL8080 := fmt.Sprintf("http://%s:8080/", lbDNSName)
	testURL8081 := fmt.Sprintf("http://%s:8081/", lbDNSName)
	expectedText := "Hello, world!"
	tlsConfig := tls.Config{
		MinVersion: tls.VersionTLS13,
	}
	maxRetries := 10
	timeBetweenRetries := 30 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		testURL8080,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
	http_helper.HttpGetWithRetry(
		t,
		testURL8081,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
}

func TestTerraformAwsEcsServiceNlb(t *testing.T) {
	t.Parallel()

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../", "examples/load-balancer")

	ecsServiceName := fmt.Sprintf("terratest-simple-%s", strings.ToLower(random.UniqueId()))
	awsRegion := "us-west-2"
	vpcAzs := aws.GetAvailabilityZones(t, awsRegion)[:3]

	terraformOptions := &terraform.Options{
		// The path to where our Terraform code is located
		TerraformDir: tempTestFolder,

		// Variables to pass to our Terraform code using -var options
		Vars: map[string]interface{}{
			"test_name":     ecsServiceName,
			"vpc_azs":       vpcAzs,
			"region":        awsRegion,
			"associate_alb": false,
			"associate_nlb": true,
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	}

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	lbDNSName := terraform.Output(t, terraformOptions, "lb_dns_name")
	testURL8080 := fmt.Sprintf("http://%s:8080/", lbDNSName)
	testURL8081 := fmt.Sprintf("http://%s:8081/", lbDNSName)
	expectedText := "Hello, world!"
	tlsConfig := tls.Config{
		MinVersion: tls.VersionTLS13,
	}
	maxRetries := 20
	timeBetweenRetries := 30 * time.Second

	http_helper.HttpGetWithRetry(
		t,
		testURL8080,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
	http_helper.HttpGetWithRetry(
		t,
		testURL8081,
		&tlsConfig,
		200,
		expectedText,
		maxRetries,
		timeBetweenRetries,
	)
}
