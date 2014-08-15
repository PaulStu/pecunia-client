/**
 * Copyright (c) 2013, 2014, Pecunia Project. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; version 2 of the
 * License.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
 * 02110-1301  USA
 */

#import "AccountStatement.h"
#import "BankAccount.h"
#import "BankStatement.h"
#import "NSString+PecuniaAdditions.h"
#import "MOAssistant.h"
#import "StatCatAssignment.h"
#import "BankStatementPrintView.h"

@implementation AccountStatementParameters

@synthesize canIndex;
@synthesize formats;
@synthesize needsReceipt;

- (BOOL)supportsFormat: (AccountStatementFormat)format {
    NSString *f = [NSString stringWithFormat:@"%d", format];
    return [formats hasSubstring:f];
}

@end


@implementation AccountStatement

@dynamic document;
@dynamic format;
@dynamic startDate;
@dynamic endDate;
@dynamic info;
@dynamic conditions;
@dynamic advertisement;
@dynamic iban;
@dynamic bic;
@dynamic name;
@dynamic confirmationCode;
@dynamic account;
@synthesize statements;

- (void)convertStatementsToPDFForAccount: (BankAccount*)acct {
    if (self.statements == nil) {
        return;
    }
    
    if (self.format.intValue != AccountStatement_MT940) {
        return;
    }
    
    NSManagedObjectContext *context = MOAssistant.assistant.memContext;
    NSMutableArray *stats = [NSMutableArray array];

    // insert BankAccount
    BankAccount *account = [NSEntityDescription insertNewObjectForEntityForName: @"BankAccount" inManagedObjectContext: context];
    account.accountNumber = acct.accountNumber;
    account.bankCode = acct.bankCode;
    account.accountSuffix = acct.accountSuffix;
    account.name = acct.name;
    account.bankName = acct.bankName;
    account.currency = acct.currency;
    
    // insert StatCatAssignments
    for (BankStatement *statement in self.statements) {
        statement.account = account;
        StatCatAssignment *stat = [NSEntityDescription insertNewObjectForEntityForName: @"StatCatAssignment" inManagedObjectContext: context];
        stat.statement = statement;
        stat.value = statement.value;
        [stats addObject:stat];
    }
    
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    [printInfo setTopMargin: 45];
    [printInfo setBottomMargin: 45];
    NSMutableData    *pdfData = [[NSMutableData alloc] init];
    NSView           *view = [[BankStatementPrintView alloc] initWithStatements: stats printInfo: printInfo];
    NSPrintOperation *printOp = [NSPrintOperation PDFOperationWithView:view insideRect:[view frame] toData:pdfData printInfo:printInfo];
    [printOp runOperation];
    
    self.document = pdfData;
}

@end