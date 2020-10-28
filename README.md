# BMI Calculator (iOS)

This is a simple **BMI Calculator** app to demonstrate the use of `codemagic.yaml` for building native iOS app on [Codemagic](https://codemagic.io/start/).

## Screenshots

<p align="center">
  <img width="250" src="https://github.com/sbis04/bmi_ios/raw/master/screenshots/bmi_calculate_screen.png" alt="Calculation Screen"/>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <img width="250" src="https://github.com/sbis04/bmi_ios/raw/master/screenshots/bmi_result_screen.png" alt="Result Screen"/>
</p>

## Codemagic YAML Template

You can use the following `codemagic.yaml` file for your build pipeline, it contains three workflows for generating debug build, signed build, and generating and uploading the build analysis result to **SonarQube**.

```yaml
# You can get more information regarding the YAML file here:
# https://docs.codemagic.io/building/yaml

# Workflow setup for building Native iOS project
workflows:
  # The following workflow is for generating a debug build (.app)
  ios-project-debug: # workflow ID
    name: Native iOS # workflow name
    environment:
      xcode: latest
      cocoapods: default
    scripts:
      - |
        # run tests
        xcodebuild \
        -project "<your_xcode_project_name>.xcodeproj" \
        -scheme "<your_scheme>" \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 11 Pro Max,OS=13.4' \
        clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
      - |
        # build .app
        xcodebuild build -project "<your_xcode_project_name>.xcodeproj" -scheme "<your_scheme>" CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
    artifacts:
      - $HOME/Library/Developer/Xcode/DerivedData/**/Build/**/*.app
    publishing:
      email:
        recipients:
          - name@example.com # enter your email id here

  # The following workflow is for generating a release build (.ipa)
  ios-project-release: # workflow ID
    name: Native iOS # workflow name
    environment:
      vars:
        CM_CERTIFICATE: Encrypted(...) # enter the encrypted version of your certificate
        CM_CERTIFICATE_PASSWORD: Encrypted(...) # enter the encrypted version of your certificate password
        CM_PROVISIONING_PROFILE: Encrypted(...) # enter the encrypted version of your provisioning profile
      xcode: latest
      cocoapods: default
    scripts:
      - keychain initialize
      - |
        # set up provisioning profiles
        PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
        mkdir -p "$PROFILES_HOME"
        PROFILE_PATH="$(mktemp "$PROFILES_HOME"/$(uuidgen).mobileprovision)"
        echo ${CM_PROVISIONING_PROFILE} | base64 --decode > $PROFILE_PATH
        echo "Saved provisioning profile $PROFILE_PATH"
      - |
        # set up signing certificate
        echo $CM_CERTIFICATE | base64 --decode > /tmp/certificate.p12
        keychain add-certificates --certificate /tmp/certificate.p12 --certificate-password $CM_CERTIFICATE_PASSWORD
      - |
        # run tests
        xcodebuild \
        -project "<your_xcode_project_name>.xcodeproj" \
        -scheme "<your_scheme>" \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 11 Pro Max,OS=13.4' \
        clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
      - |
        # build ipa
        xcode-project use-profiles
        xcode-project build-ipa --project "<your_xcode_project_name>.xcodeproj" --scheme "<your_scheme>"
    artifacts:
      - build/ios/ipa/*.ipa
      - /tmp/xcodebuild_logs/*.log
    publishing:
      email:
        recipients:
          - name@example.com # enter your email id here
  ios-sonarqube:
    name: iOS sonarqube
    environment:
      vars:
        SONAR_TOKEN: Encrypted(...) # enter the encrypted version of your SonarCloud token
        SONAR_PROJECT_KEY: Encrypted(...) # enter the encrypted version of your SonarCloud project key
        SONAR_ORG_KEY: Encrypted(...) # enter the encrypted version of your SonarCloud organization key
        SONAR_PROJECT_VERSION: 1.0.0-cm
      xcode: latest
      cocoapods: default
    scripts:
      - |
        # download and install sonarqube
        wget -O $FCI_BUILD_DIR/sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.4.0.2170-macosx.zip
        unzip $FCI_BUILD_DIR/sonar-scanner.zip
        mv sonar-scanner-* sonar-scanner
      - |
        # generate test coverage result
        xcodebuild \
        -project "<project_name>.xcodeproj" \
        -scheme "<scheme_name>" \
        -sdk iphonesimulator \
        -destination 'platform=iOS Simulator,name=iPhone 11 Pro,OS=14.0' \
        -derivedDataPath Build/ \
        -enableCodeCoverage YES \
        clean build test CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO
      - |
        # convert coverage report to sonarqube format
        bash xccov-to-sonarqube-generic.sh Build/Logs/Test/*.xcresult/ > sonarqube-generic-coverage.xml
      - |
        # sonarqube analysis
        export PATH=$PATH:$FCI_BUILD_DIR/sonar-scanner/bin
        sonar-scanner \
        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
        -Dsonar.organization=$SONAR_ORG_KEY \
        -Dsonar.host.url=https://sonarcloud.io \
        -Dsonar.login=$SONAR_TOKEN \
        -Dsonar.projectVersion=$SONAR_PROJECT_VERSION \
        -Dsonar.sources=. \
        -Dsonar.cfamily.build-wrapper-output.bypass=true \
        -Dsonar.coverageReportPaths=sonarqube-generic-coverage.xml \
        -Dsonar.c.file.suffixes=- \
        -Dsonar.cpp.file.suffixes=- \
        -Dsonar.objc.file.suffixes=-
    publishing:
      email:
        recipients:
          - name@example.com # enter your email

```

## Converting `.xcresult` to `.xml` file

You have to upload the build result in **XML** format to [SonarQube](https://www.sonarqube.org/). Create a file called `xccov-to-sonarqube-generic.sh` and store it in the root project directory.

```sh
#!/usr/bin/env bash
set -euo pipefail

function convert_file {
  local xccovarchive_file="$1"
  local file_name="$2"
  echo "  <file path=\"$file_name\">"
  local line_coverage_cmd="xcrun xccov view"
  if [[ $@ == *".xcresult"* ]]; then
    line_coverage_cmd="$line_coverage_cmd --archive"
  fi
  line_coverage_cmd="$line_coverage_cmd --file \"$file_name\" \"$xccovarchive_file\""
  eval $line_coverage_cmd | \
    sed -n '
    s/^ *\([0-9][0-9]*\): 0.*$/    <lineToCover lineNumber="\1" covered="false"\/>/p;
    s/^ *\([0-9][0-9]*\): [1-9].*$/    <lineToCover lineNumber="\1" covered="true"\/>/p
    '
  echo '  </file>'
}

function xccov_to_generic {
  echo '<coverage version="1">'
  for xccovarchive_file in "$@"; do
    local file_list_cmd="xcrun xccov view"
    if [[ $@ == *".xcresult"* ]]; then
      file_list_cmd="$file_list_cmd --archive"
    fi
    file_list_cmd="$file_list_cmd --file-list \"$xccovarchive_file\""
    eval $file_list_cmd | while read -r file_name; do
      convert_file "$xccovarchive_file" "$file_name"
    done
  done
  echo '</coverage>'
}

xccov_to_generic "$@"
```

## License

Copyright (c) 2020 Souvik Biswas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
