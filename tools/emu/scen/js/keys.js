const m = sp.memory; return Object.keys(m).join(',') + ' | ' + Object.getOwnPropertyNames(Object.getPrototypeOf(m)).join(',');
