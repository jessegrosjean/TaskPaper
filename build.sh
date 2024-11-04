#!/bin/sh

function packageDMG() {
    local APP_NAME=$1
    local PRODUCT_NAME=$2
    local BUNDLE_VERSION=$3
    local SHORT_VERSION_STRING=$4
    local DMG_NAME=$5
    local ARCHIVE="./build/$APP_NAME.xcarchive"
    local ARCHIVE_APP="$ARCHIVE/Products/Applications/$APP_NAME.app"
    local ARCHIVE_APP_PLIST="$ARCHIVE_APP/Contents/Info.plist"
    local RELEASE_CANDIDATE_FOLDER="build/$APP_NAME-Candidate-($BUNDLE_VERSION)/"

    # Create release candidate folder where results are placed
    mkdir -p "$RELEASE_CANDIDATE_FOLDER"

    # Set CFBundleShortVersionString in Archive's Info.plist
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \"$SHORT_VERSION_STRING\"" "${ARCHIVE_APP_PLIST}"

    # Export App from Archive
    local EXPORTED_APP="./build/$APP_NAME.app"
    xcodebuild -exportArchive -exportOptionsPlist "./$APP_NAME/ExportOptions-direct.plist" -archivePath "$ARCHIVE" -exportPath "./build/"

    # Xcodes export strips get-task-allow entitlement. So manually resign to add it back
    codesign --timestamp --options runtime --entitlements "$EXPORTED_APP/Contents/Resources/$APP_NAME-Direct.entitlements" -f -s "Developer ID Application: Jesse Grosjean" "$EXPORTED_APP"

    # Create DMG from exported app
    local DMG_PATH="build/$DMG_NAME"
    echo "Begin DMGCanvas"
    dmgcanvas "$APP_NAME/DMGTemplate-Direct.dmgCanvas/" "$DMG_PATH"
    echo "End DMGCanvas"
    cp "$DMG_PATH" "$RELEASE_CANDIDATE_FOLDER"
    cp "$DMG_PATH" "$RELEASE_CANDIDATE_FOLDER/$PRODUCT_NAME.dmg"
    local DMG_SIZE=$(stat -f %z "$DMG_PATH")
    rm -rd "$EXPORTED_APP"
    rm -rd "$DMG_PATH"
}

function createFeed() {
    local APP_NAME=$1
    local PRODUCT_NAME=$2
    local BUNDLE_VERSION=$3
    local SHORT_VERSION_STRING=$4
    local DMG_NAME=$5
    local FEED_NAME=$6
    local MIN_SYSTEM_VERSION=$7

    local RELEASE_CANDIDATE_FOLDER="build/$APP_NAME-Candidate-($BUNDLE_VERSION)/"
    local DMG_PATH="$RELEASE_CANDIDATE_FOLDER/$DMG_NAME"
    local DMG_URL="https://www.$APP_NAME.com/assets/app/$PRODUCT_NAME.dmg"
    local DMG_SIZE=$(stat -f %z "$DMG_PATH")
    local FEED_PATH="$RELEASE_CANDIDATE_FOLDER/$FEED_NAME"
    local PUBDATE=$(date +"%a, %d %b %G %T %z")
    local RELEASE_NOTES=$(./Markdown.pl "$APP_NAME/$APP_NAME-Direct-Notes.md")
    cat <<EOF > "$FEED_PATH"
<?xml version="1.0" encoding="utf-8"?>
<rss xmlns:atom="http://www.w3.org/2005/Atom" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" version="2.0">
  <channel>
    <title>$APP_NAME Releases</title>
    <description>Most recent releases with download links to new application version.</description>
    <language>en</language>
    <ttl>60</ttl>
    <item>
      <title>Version $SHORT_VERSION_STRING ($BUNDLE_VERSION)</title>
      <pubDate>$PUBDATE</pubDate>
      <description><![CDATA[$RELEASE_NOTES]]></description>
      <sparkle:version>$BUNDLE_VERSION</sparkle:version>
      <enclosure
        url="$DMG_URL"
        type="application/x-apple-diskimage"
        length="$DMG_SIZE"
        sparkle:version="$BUNDLE_VERSION"
        sparkle:shortVersionString="$SHORT_VERSION_STRING"
        sparkle:minimumSystemVersion="$MIN_SYSTEM_VERSION"
      />
    </item>
  </channel>
</rss>
EOF
}

function buildApp() {
    local APP_NAME=$1

    # Plist paths
    local INFOPLIST_FILE="./$APP_NAME/$APP_NAME-Info.plist"
    local PADDLE_INFOPLIST_FILE="./$APP_NAME/$APP_NAME-Direct-Info.plist"
    local SETAPP_INFOPLIST_FILE="./$APP_NAME/$APP_NAME-Setapp-Info.plist"

    # Plist extractions
    local SHORT_VERSION_STRING=$(xcodebuild -project "./TaskPaper.xcodeproj" -scheme "$APP_NAME" -showBuildSettings | grep "MARKETING_VERSION" | sed 's/[ ]*MARKETING_VERSION = //')
    local SHORT_VERSION_STRING_PREVIEW="$SHORT_VERSION_STRING Preview"
    local BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_FILE}")
    local PRODUCT_NAME="$APP_NAME-$SHORT_VERSION_STRING"
    local PRODUCT_NAME="${PRODUCT_NAME// /-}"

    # Plist version update and sync
    #local BUNDLE_VERSION=$(($BUNDLE_VERSION + 1))
    local BUNDLE_VERSION=484
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "${INFOPLIST_FILE}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "${PADDLE_INFOPLIST_FILE}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUNDLE_VERSION" "${SETAPP_INFOPLIST_FILE}"

    # Tag and commit new build number
    #git add .
    #local TAG_NAME="$APP_NAME-$SHORT_VERSION_STRING ($BUNDLE_VERSION)"
    #local TAG_NAME_NO_SPACES=`echo $TAG_NAME | sed -e 's/ /_/g'`
    #git commit -m "Archive Build $TAG_NAME"
    #git tag -a -m "Archive Build Tag" "$TAG_NAME_NO_SPACES"
    #git push origin --tags

    # Create Relase Candidate Folder
    local RELEASE_CANDIDATE_FOLDER="build/$APP_NAME-Candidate-($BUNDLE_VERSION)"

    mkdir "$RELEASE_CANDIDATE_FOLDER"
    open "$RELEASE_CANDIDATE_FOLDER"

    # Package Direct Release
    xcodebuild -project "./TaskPaper.xcodeproj" -scheme "$APP_NAME Direct" -archivePath "build/$APP_NAME" clean archive
    mv "build/$APP_NAME.xcarchive/dSYMs" "$RELEASE_CANDIDATE_FOLDER/Direct-dSYMs"
    packageDMG $APP_NAME $PRODUCT_NAME $BUNDLE_VERSION $SHORT_VERSION_STRING "$APP_NAME.dmg"
    local MIN_SYSTEM_VERSION=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "build/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app/Contents/Info.plist")
    cp "build/$APP_NAME.xcarchive/dSYMs" "$RELEASE_CANDIDATE_FOLDER/Direct/dSYMs"
    createFeed $APP_NAME $PRODUCT_NAME $BUNDLE_VERSION $SHORT_VERSION_STRING "$APP_NAME.dmg" "$APP_NAME.rss" $MIN_SYSTEM_VERSION

    # Package Direct Preview Release
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \"$SHORT_VERSION_STRING_PREVIEW\"" "${PADDLE_INFOPLIST_FILE}"
    xcodebuild -project "./TaskPaper.xcodeproj" -scheme "$APP_NAME Direct" -archivePath "build/$APP_NAME" clean archive
    cp "build/$APP_NAME.xcarchive/dSYMs" "$RELEASE_CANDIDATE_FOLDER/Preview-dSYMs"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \"$SHORT_VERSION_STRING\"" "${PADDLE_INFOPLIST_FILE}"
    packageDMG $APP_NAME "$PRODUCT_NAME-Preview" $BUNDLE_VERSION "$SHORT_VERSION_STRING Preview" "$APP_NAME-Preview.dmg"
    rm -rd "build/$APP_NAME.xcarchive"
    createFeed $APP_NAME "$PRODUCT_NAME-Preview" $BUNDLE_VERSION $SHORT_VERSION_STRING "$APP_NAME-Preview.dmg" "$APP_NAME-Preview.rss" $MIN_SYSTEM_VERSION

    # App Store Build, archived to Xcode location
    xcodebuild -project "./TaskPaper.xcodeproj" -scheme "$APP_NAME" clean archive

    # Package Setapp Release
    mkdir "$RELEASE_CANDIDATE_FOLDER/Setapp"
    xcodebuild -project "./TaskPaper.xcodeproj" -scheme "$APP_NAME Setapp" -archivePath "build/$APP_NAME-Setapp" clean archive
    xcodebuild -exportArchive -exportOptionsPlist "./$APP_NAME/ExportOptions-direct.plist" -archivePath "build/$APP_NAME-Setapp.xcarchive" -exportPath "./build/"
    codesign --timestamp --options runtime --entitlements "./$APP_NAME/$APP_NAME-Direct.entitlements" -f -s "Developer ID Application: Jesse Grosjean" "./build/$APP_NAME.app"
    cp "build/$APP_NAME-Setapp.xcarchive/dSYMs" "$RELEASE_CANDIDATE_FOLDER/Setapp/dSYMs"

    echo "Begin DMGCanvas for notarize side effect"
    dmgcanvas "$APP_NAME/DMGTemplate-Setapp.dmgCanvas/" "./build/$APP_NAME.dmg"
    echo "End DMGCanvas"
    xcrun stapler staple "./build/$APP_NAME.app" # should work since DMGCanvas did notarize
    
    mkdir "$RELEASE_CANDIDATE_FOLDER/Setapp/$APP_NAME"
    mv "./build/$APP_NAME.app" "$RELEASE_CANDIDATE_FOLDER/Setapp/$APP_NAME/$APP_NAME.app" # if use cp -r it breaks signature
    cp "./$APP_NAME/SetappAppIcon.png" "$RELEASE_CANDIDATE_FOLDER/Setapp/$APP_NAME/AppIcon.png"
    
    /usr/bin/ditto -c -k --keepParent "$RELEASE_CANDIDATE_FOLDER/Setapp/$APP_NAME" "$RELEASE_CANDIDATE_FOLDER/Setapp/$APP_NAME.zip"

    rm -rd "build/$APP_NAME.dmg"
    rm -rd "build/$APP_NAME-Setapp.xcarchive"
}

buildApp TaskPaper
