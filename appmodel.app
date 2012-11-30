<?xml version="1.0" encoding="ASCII"?>
<app:application xmlns:app="http://www.sierrawireless.com/airvantage/application/1.0" name="wshop12" revision="1.0.0" type="wshop12">
  <capabilities>
    <communication use="aleos"/>
    <data>
      <encoding type="AWTDA2">
        <asset default-label="Arduino" id="arduino">
          <variable default-label="Luminosity" path="luminosity" type="double"/>
          <variable default-label="Temperature" path="temperature" type="double"/>
          <variable default-label="Humidity" path="humidity" type="double"/>
          <variable default-label="Button" path="button" type="boolean"/>
          <setting default-label="Light" path="light" type="boolean"/>
          <command default-label="Blink" path="blink"/>
        </asset>
      </encoding>
    </data>
  </capabilities>
  <application-manager use="READYAGENT_APPCON"/>
  <binaries>
    <binary file="phony.tar"/>
  </binaries>
</app:application>