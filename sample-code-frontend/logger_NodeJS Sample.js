const winston = require('winston');
const UUID = require('uuid/v1');
const fs = require("fs");
const lib = require('../Lib/index');

class LogService {


    constructor(config) {
        this._defaultFilename = "log.log";
        this._defaultLogLevel = "info";
        try {
            this._correlationId = UUID();
            if (config) {
                this._logger = new(winston.Logger)({
                    level: config.logLevel || this._defaultLogLevel
                });
                if (config.console) {
                    if (config.console.enable) {
                        this._logger.add(winston.transports.Console);
                    } else {
                        this._logger.remove(winston.transports.Console);
                    }
                } else {
                    this._logger.remove(winston.transports.Console);
                }

                if (config.file) {
                    if (config.file.enable) {
                        this._logger.add(winston.transports.File, {
                            filename: config.file.filename || this._defaultFilename
                        });
                    } else {
                        this._logger.remove(winston.transports.File);
                    }
                } else {
                    this._logger.remove(winston.transports.File);
                }
            } else {
                this._logger = new(winston.Logger)({
                    level: this._defaultLogLevel
                });
                this._logger.add(winston.transports.Console);
            }

            this.info(this.constructor.name + ' create successfully.');
            this.verbose('Config: ' + JSON.stringify(config));


        } catch (e) {
            console.log('Error: ' + this.constructor.name + ' fail to create\nDetail: ' + e.toString());
        }
    }


    log(level, message) {
        this._logger.log(level, this.formatMessage(message));
    }

    error(message) {
        this._logger.error(this.formatMessage(message));
    }

    warn(message) {
        this._logger.warn(this.formatMessage(message));
    }

    info(message) {
        this._logger.info(this.formatMessage(message));
    }

    debug(message) {
        this._logger.debug(this.formatMessage(message));
    }

    verbose(message) {
        this._logger.verbose(this.formatMessage(message));
    }

    formatMessage(message) {
        let errorMessage = lib.dumpError(message);
        return `Correlation ID: ${this._correlationId}, ${errorMessage}`;
    }

    formatProcessMessage(message, processid) {
        return "Process ID: " + processid + ", " + message;
    }


}
