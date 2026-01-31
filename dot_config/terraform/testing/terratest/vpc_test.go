// Package test contains infrastructure tests for {{PROJECT_NAME}}
package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/aws"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestVPCCreation tests that the VPC module creates expected resources
func TestVPCCreation(t *testing.T) {
	t.Parallel()

	// Arrange
	awsRegion := "{{AWS_REGION}}"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"project_name": "{{PROJECT_NAME}}-test",
			"environment":  "test",
			"vpc_cidr":     "10.99.0.0/16",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	// Cleanup resources after test
	defer terraform.Destroy(t, terraformOptions)

	// Act
	terraform.InitAndApply(t, terraformOptions)

	// Assert
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	// Verify VPC exists in AWS
	vpc := aws.GetVpcById(t, vpcID, awsRegion)
	require.NotNil(t, vpc, "VPC should exist")

	// Verify VPC CIDR
	assert.Equal(t, "10.99.0.0/16", *vpc.CidrBlock, "VPC CIDR should match")
}

// TestVPCSubnets tests that subnets are created correctly
func TestVPCSubnets(t *testing.T) {
	t.Parallel()

	// Arrange
	awsRegion := "{{AWS_REGION}}"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"project_name":       "{{PROJECT_NAME}}-subnet-test",
			"environment":        "test",
			"vpc_cidr":           "10.98.0.0/16",
			"availability_zones": []string{awsRegion + "a", awsRegion + "c"},
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	// Act
	terraform.InitAndApply(t, terraformOptions)

	// Assert
	publicSubnetIDs := terraform.OutputList(t, terraformOptions, "public_subnet_ids")
	privateSubnetIDs := terraform.OutputList(t, terraformOptions, "private_subnet_ids")

	assert.Len(t, publicSubnetIDs, 2, "Should have 2 public subnets")
	assert.Len(t, privateSubnetIDs, 2, "Should have 2 private subnets")

	// Verify subnets exist
	for _, subnetID := range publicSubnetIDs {
		subnet := aws.GetSubnetById(t, subnetID, awsRegion)
		require.NotNil(t, subnet, "Public subnet should exist")
		assert.True(t, *subnet.MapPublicIpOnLaunch, "Public subnet should auto-assign public IPs")
	}
}

// TestVPCTags tests that resources are properly tagged
func TestVPCTags(t *testing.T) {
	t.Parallel()

	// Arrange
	awsRegion := "{{AWS_REGION}}"
	projectName := "{{PROJECT_NAME}}-tag-test"
	environment := "test"

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../modules/vpc",
		Vars: map[string]interface{}{
			"project_name": projectName,
			"environment":  environment,
			"vpc_cidr":     "10.97.0.0/16",
		},
		EnvVars: map[string]string{
			"AWS_DEFAULT_REGION": awsRegion,
		},
	})

	defer terraform.Destroy(t, terraformOptions)

	// Act
	terraform.InitAndApply(t, terraformOptions)

	// Assert
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	vpc := aws.GetVpcById(t, vpcID, awsRegion)

	// Check tags
	tags := make(map[string]string)
	for _, tag := range vpc.Tags {
		tags[*tag.Key] = *tag.Value
	}

	assert.Equal(t, projectName, tags["Project"], "Project tag should match")
	assert.Equal(t, environment, tags["Environment"], "Environment tag should match")
}
