#include <spawn.h>
#import <UIKit/UIKit.h>

extern char **environ;

void run_cmd(char *cmd) {
    // UNTESTED BEGIN
    if (strcmp(cmd, "kill 1") || strcmp(cmd, "halt") || strcmp(cmd, "ldRun")) {
        setgid(0);
        setuid(0);
    } else {
        setgid(501);
        setuid(501);
    }
    // UNTESTED END

    pid_t pid;
    char *argv[] = {"sh", "-c", cmd, NULL};
    int status;
    status = posix_spawn(&pid, "/bin/sh", NULL, NULL, (char* const*)argv, environ);
    if (status == 0) {
        printf("Child pid: %i\n", pid);
        if (waitpid(pid, &status, 0) != -1) {
            printf("Child exited with status %i\n", status);
        } else {
            perror("waitpid");
        }
    } else {
        printf("posix_spawn: %s\n", strerror(status));
    }
}


@interface PSUIPrefsListController : UIViewController
- (void)alertWithMessage:(NSString *)message handler:(void (^)(void))handler;
@end


%hook PSUIPrefsListController

- (void)viewDidLoad {
    %orig;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Power" style:UIBarButtonItemStylePlain target:self action:@selector(handlePower)];
}

%new
- (void)handlePower {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"PowerAction" message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *rebootAlertAction = [UIAlertAction actionWithTitle:@"Reboot" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This will REBOOT your device.\n\nContinue?" handler:^{
            setuid(0);
            setgid(0);
            run_cmd("kill 1");
        }];
    }];

    UIAlertAction *shutdownAlertAction = [UIAlertAction actionWithTitle:@"Shutdown" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This will SHUTDOWN your device.\n\nContinue?" handler:^{
            setuid(0);
            setgid(0);
            run_cmd("halt");
        }];
    }];

    UIAlertAction *softRebootAlertAction = [UIAlertAction actionWithTitle:@"Soft Reboot" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This will run ldrestart your device. This will stop all apps!\n\nContinue?" handler:^{
            setuid(0);
            setgid(0);
            run_cmd("ldrestart");
        }];
    }];

    UIAlertAction *respringAlertAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This will Respring your device. This will stop all apps!\n\nContinue?" handler:^{
            run_cmd("killall -9 SpringBoard");
        }];
    }];

    UIAlertAction *safeModeAlertAction = [UIAlertAction actionWithTitle:@"Safe Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This will only respring your device since you have substrate. This will stop all apps!\n\nContinue?" handler:^{
            run_cmd("touch /var/mobile/Library/Preferences/com.saurik.mobilesubstrate.dat; killall SpringBoard");
        }];
    }];

    UIAlertAction *refreshCacheAlertAction = [UIAlertAction actionWithTitle:@"Refresh Cache" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertWithMessage:@"This refreshes the SpringBoard so you can see your new apps without respringing. This will temporarily freeze your Home Screen (Exit this app after this is complete)!\n\nContinue?" handler:^{
            run_cmd("uicache --all");
        }];
    }];

    [alertController addAction:rebootAlertAction];
    [alertController addAction:shutdownAlertAction];
    [alertController addAction:softRebootAlertAction];
    [alertController addAction:respringAlertAction];
    [alertController addAction:safeModeAlertAction];
    [alertController addAction:refreshCacheAlertAction];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

%new
- (void)alertWithMessage:(NSString *)message handler:(void (^)(void))handler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:message preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *yesAlertAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        handler();
    }];

    [alertController addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:yesAlertAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

%end
