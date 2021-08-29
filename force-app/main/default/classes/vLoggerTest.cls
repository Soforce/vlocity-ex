@isTest
private class vLoggerTest {
    @isTest
    private static void testAll() {
        System.debug(vLogger.isLogging);
        vLogger.isLogging = true;

        vLogger.writeVar('isLogging', vLogger.isLogging);

        vLogger.write('debugMessage');
        vLogger.writeErr('errMessage');
        vLogger.writeFine('fineMessage');
        vLogger.writeInfo('infoMessage');

        try {
            Integer d = 0;
            Integer y = 10 / d;
        } catch (Exception ex) {
            vLogger.write(ex);
        }
    }
}