#!/bin/bash
# Original by Kristjan Krusic aka. krusic22
# Modified by HSGamer
# Don't forget to adjust the variables according your own needs!
# This is an Java 11+ optimised script! Get the most recent AdoptJDK or ZuluJDK for ARM.
# This script is speed-optimized and won't reduce ram use!
# Less time spent on GC, the better the performance, but possibly higher ram usage.
# Note: 1G = 1024M

# The Java run program
JAVA_RUN="java"
# USE VALUES IN M! Sometimes setting this to the same value as MAX_RAM can help performance.
START_RAM=2048
# USE VALUES IN M!
MAX_RAM=2048
# Jar name, quite self-explanatory.
JAR_NAME=server.jar
# Delay before restarting
DELAY_RESTART=5
###
###
# Enable patching the jar file
PATCH=true
# The patcher file name
PATCHER=patcher.jar
# The patcher download link
PATCHER_LINK="https://github.com/KibbleLands/KibblePatcher/releases/download/1.6.3/KibblePatcher-1.6.3.jar"
# The patched jar name
PATCHED_FILE=server-patched.jar
###
###
# PaperMC API Settings. More info: https://papermc.io/api/docs/swagger-ui/index.html?configUrl=/api/openapi/swagger-config
PROJECT="paper"
VERSION="1.16.5"
# Note: latest is not actually a part of the API, so the script gets the latest build ID using the API first.
BUILD="latest"
###
###
# Auto updater toggle.
UPDATE=true
# After how many restarts should the script attempt to update the jar.
# Note, the jar will always be updated on first startup!
UPDATE_AFTER="1"
# Default is new, using the PaperMC Donwnload API, use old if you want to download from a link.
UPDATER_VERSION="old"
# Update program. Current options are curl and wget.
UPDATE_PROGRAM="wget"
# OLD updater link
# Here are some download links from some notable forks of Spigot/Paper
# - Purpur: https://purpur.pl3x.net/api/v1/purpur/${VERSION}/latest/download
# - Airplane: https://dl.airplane.gg/latest/Airplane-JDK11/launcher-airplane.jar
# - Tuinity: https://ci.codemc.io/job/Spottedleaf/job/Tuinity/lastSuccessfulBuild/artifact/tuinity-paperclip.jar
# - Yatopia: https://api.yatopiamc.org/v2/stableBuild/download?branch=ver/${VERSION}
# - Origami: https://ci.minebench.de/job/Origami/lastSuccessfulBuild/artifact/origamicrane.jar
JAR_LINK="https://purpur.pl3x.net/api/v1/purpur/${VERSION}/latest/download"
###
# Only use one garbage collector!
GONE=true               #Use G1 GC. Flags from: https://aikar.co/2018/07/02/tuning-the-jvm-g1gc-garbage-collector-flags-for-minecraft/
SHEN=false              #Use ShenandoahGC. Untested for now.
ZGC=false               #The Z Garbage Collector. Please read: https://krusic22.com/2020/03/25/higher-performance-crafting-using-jdk11-and-zgc/
###
# Experimental stuff. Good luck.
EXP=true               #Enable experimental stuff... It might cause unexpected problems but I haven't noticed any yet.
LP=true                #Enable only if you have Large/Huge Pages enabled, transparent pages are recommended for regular users.
X86=true               #Flags that should only work on X86.
###
# Jar parameters like --nogui or --forceUpgrade, you can list all options by setting this to --help.
AFTERJAR="--nogui"
###
# Unused Parameters, you might want to use some of them depending on your configuration, copy the parameters under Normal Parameters,
# since IgnoreUnrecognizedVMOptions is set, unknown / invalid options will be ignored instead of stopping the JVM.
# -XX:ActiveProcessorCount=4 #This should restrict the use of CPU cores, although this is more of a suggestion than a constraint.
# -Xlog:gc*:file=GC.log #This will log GC to a file called GC.log, which can be used to debug GC, replace 'file=GB.log' with 'stdout' if you want logging to the console. Other options you can change/add pid,level,tags,...
# -Xlog:gc*:file=GC.log:time,uptimemillis,tid #Same as above, but with local time, uptime/runtime and thread IDs.
# -Xlog:gc*=debug:file=GC.log:time,uptimemillis,tid #Same as above, but with some extra debug. Warning: This is going to grow quickly!
###
# Normal Parameters
PARMS="
-server
-XX:+IgnoreUnrecognizedVMOptions
-XX:+UnlockExperimentalVMOptions
-XX:+UnlockDiagnosticVMOptions
-XX:+UseGCOverheadLimit
-XX:+ParallelRefProcEnabled
-XX:-OmitStackTraceInFastThrow
-XX:+ShowCodeDetailsInExceptionMessages
-XX:+PerfDisableSharedMem
"
# G1 optimizations...
GONEP="
-XX:MaxGCPauseMillis=200
-XX:G1HeapWastePercent=5
-XX:G1MixedGCCountTarget=4
-XX:G1MixedGCLiveThresholdPercent=90
-XX:G1RSetUpdatingPauseTimePercent=5
-XX:SurvivorRatio=32
-XX:MaxTenuringThreshold=1
-Dusing.aikars.flags=https://mcflags.emc.gs
-Daikars.new.flags=true
"
# G1 Additional optimizations for small RAMs
GONEP1="
-XX:G1NewSizePercent=30
-XX:G1MaxNewSizePercent=40
-XX:G1HeapRegionSize=8M
-XX:G1ReservePercent=20
-XX:InitiatingHeapOccupancyPercent=15
"
# G1 Additional optimizations for big RAMs (11GB+)
GONEP2="
-XX:G1NewSizePercent=40
-XX:G1MaxNewSizePercent=50
-XX:G1HeapRegionSize=16M
-XX:G1ReservePercent=15
-XX:InitiatingHeapOccupancyPercent=20
"
# Shenandoah options that might be worth looking into, some of the options only got added in JDK12+, currently set to default values from AdoptJDK13.
SHENP="
-XX:ShenandoahAllocSpikeFactor=5
-XX:ShenandoahControlIntervalAdjustPeriod=1000
-XX:ShenandoahControlIntervalMax=10
-XX:ShenandoahControlIntervalMin=1
-XX:ShenandoahInitFreeThreshold=70
-XX:ShenandoahFreeThreshold=10
-XX:ShenandoahGarbageThreshold=60
-XX:ShenandoahGuaranteedGCInterval=300000
-XX:ShenandoahMinFreeThreshold=10
-XX:-ShenandoahRegionSampling
-XX:ShenandoahRegionSamplingRate=40
-XX:ShenandoahParallelSafepointThreads=4
-XX:+ShenandoahOptimizeInstanceFinals
-XX:+ShenandoahOptimizeStaticFinals
"
# ZGC options. Most of them only available in JDK13+.
# Copy them to the ZGCP area.
#-XX:-ZUncommit
#-XX:ZUncommitDelay=5
#-XX:SoftMaxHeapSize=4G
#-XX:+ZCollectionInterval=5
#-XX:ZAllocationSpikeTolerance=2.0
ZGCP="

"
# Experimental options... Use at your own risk!
if [ "$EXP" = true ]; then
echo "You have enabled Experimental Options! Use at your own risk!"
PARMS="$PARMS -XX:+ExitOnOutOfMemoryError -XX:+AlwaysPreTouch -XX:+UseAdaptiveGCBoundary -XX:-DontCompileHugeMethods -XX:+TrustFinalNonStaticFields -XX:+UseFastUnorderedTimeStamps "
fi
# Large Pages config
if [ "$LP" = true ]; then
PARMS="$PARMS -XX:+UseTransparentHugePages -XX:+UseLargePagesInMetaspace -XX:+UseLargePagesInMetaspace -XX:LargePageSizeInBytes=2M -XX:+UseLargePages"
fi
# G1 Is only useful when you have some ram... The old recommendation was 4GB, but I've seen improvements even on 512MB.
if [ "$GONE" = true ]; then
    PARMS="$PARMS -XX:+DisableExplicitGC -XX:-UseParallelGC -XX:-UseParallelOldGC -XX:+UseG1GC $GONEPM"
    if [ $MAX_RAM -gt 11264 ]; then
        PARMS="$PARMS $GONEP2"
    else
        PARMS="$PARMS $GONEP1"
    fi
fi
# Experimental ShenandoahGC
if [ "$SHEN" = true ]; then
    PARMS="$PARMS -XX:+DisableExplicitGC -XX:-UseParallelGC -XX:-UseParallelOldGC -XX:+UseShenandoahGC $SHENP"
fi
# Experimental ZGC
if [ "$ZGC" = true ]; then
    PARMS="$PARMS -XX:+DisableExplicitGC -XX:-UseParallelGC -XX:-UseParallelOldGC -XX:-UseG1GC -XX:+UseZGC $ZGCP"
fi
# Experimental X86 abomination, some of the flags may not be ARCH specific, so they could work on other platforms as well.
if [ "$X86" = true ]; then
    PARMS="$PARMS -XX:+UseCMoveUnconditionally -XX:+UseFPUForSpilling -XX:+UseNewLongLShift -XX:+UseVectorCmov -XX:+UseXMMForArrayCopy -XX:+UseXmmI2D -XX:+UseXmmI2F -XX:+UseXmmLoadAndClearUpper -XX:+UseXmmRegToRegMoveAll"
fi
###
# Updater. This time actually formatted for readability.
RUN=0
function Update {
    if [ "$UPDATE" = true ]; then
        if [ "$(( $RUN % $UPDATE_AFTER ))" = 0 ] || [ "$RUN" = 0 ]; then
            echo "Updating Jar..."
            #New PaperMC API updater
            if [ "$UPDATER_VERSION" = "new" ]; then
                if [ "$BUILD" = "latest" ]; then
                    if [ $UPDATE_PROGRAM = "curl" ]; then
                        BUILD=$(curl -s https://papermc.io/api/v2/projects/paper/versions/$VERSION | grep -E -o '[0-9]+' | tail -1)
                    fi
                    if [ $UPDATE_PROGRAM = "wget" ]; then
                        BUILD=$(wget -q https://papermc.io/api/v2/projects/paper/versions/$VERSION -O - | grep -E -o '[0-9]+' | tail -1)
                    fi
                fi
                JARLINK="https://papermc.io/api/v2/projects/$PROJECT/versions/$VERSION/builds/$BUILD/downloads/$PROJECT-$VERSION-$BUILD.jar"
                if [ $UPDATE_PROGRAM = "curl" ]; then
                    curl -s "$JARLINK" > "$JAR_NAME"
                fi
                if [ $UPDATE_PROGRAM = "wget" ]; then
                    wget "$JARLINK" -O "$JAR_NAME" 2>/dev/null
                fi
            fi
            #Old updater
            if [ "$UPDATER_VERSION" = "old" ]; then
                JARLINK=$JAR_LINK
                if [ $UPDATE_PROGRAM = "curl" ]; then
                    curl -s "$JARLINK" > "$JAR_NAME"
                fi
                if [ $UPDATE_PROGRAM = "wget" ]; then
                    wget "$JARLINK" -O "$JAR_NAME" 2>/dev/null
                fi
            fi
            
            if [ "$PATCH" = true ]; then
                echo "Updating patcher..."
                PATCHERLINK=$PATCHER_LINK
                if [ $UPDATE_PROGRAM = "curl" ]; then
                    curl -s "$PATCHERLINK" > "$PATCHER"
                fi
                if [ $UPDATE_PROGRAM = "wget" ]; then
                    wget "$PATCHERLINK" -O "$PATCHER" 2>/dev/null
                fi
            fi
        fi
    fi
}
# Patch function
function Patch {
    if [ "$(( $RUN % $UPDATE_AFTER ))" = 0 ] || [ "$RUN" = 0 ]; then
        if [ "$PATCH" = true ]; then
            echo "Patching!"
            java -jar $PATCHER $JAR_NAME $PATCHED_FILE
        else
            PATCHED_FILE=$JAR_NAME
        fi
    fi
}
# Run function
function Run {
    echo "Starting!"
    $JAVA_RUN -Xms$START_RAM\M -Xmx$MAX_RAM\M $PARMS -jar $PATCHED_FILE $AFTERJAR
}
###
# You can stop this script by pressing CTRL+C multiple times.
while true
do
    Update
    Patch
    RUN=$((RUN+1))
    Run

    echo "Server will restart in:"
    COUNT=$DELAY_RESTART
    while [ $COUNT -gt "0" ]; do
        echo $COUNT
        sleep 1
        COUNT=$(($COUNT - 1))
    done
done
